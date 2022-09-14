import subprocess
import threading
import argparse
from time import sleep
import pandas as pd
import datetime

NUM_OF_GPUS = 2
GPU_MEM_CAP = 32000

def import_results():
    # file_path = "D:/2021/개인연구/Xonar/git/results/v100PS2W2_results_wogroupdeps.csv"
    file_path = "v100PS2W2_results_wogroupdeps_gpuutil.csv"
    data = pd.read_csv(file_path,
                       thousands=',',
                       index_col=False,
                       encoding='utf-8')

    return data


def find_gpu_mem_used(job, data):
    dataset = job.split("_")[0]
    model = job.split("_")[1]
    sync = job.split("_")[2]
    params = job.split("_")[3]

    gpu_mem_used = []

    for gpu_idx in range(NUM_OF_GPUS):
        # gpu_mem_used.append(data.where[(data['Dataset'] == dataset)
        #                     & (data['Model'] == model)
        #                     & (data['syncronization'] == sync)
        #                     & (data['hyperparameter'] == params)
        #                     & (data['w_idx'] == 1)]['GPU_Memory(MB)'])
        gpu_mem_used.append(data.loc[(data['Dataset'] == dataset)
                                       & (data['Model'] == model)
                                       & (data['syncronization'] == sync)
                                       & (data['hyperparameter'] == params)
                                       & (data['w_idx'] == 1)]['GPU_Memory(MB)'].item())

    return gpu_mem_used


def find_gpu_active(job, data):
    dataset = job.split("_")[0]
    model = job.split("_")[1]
    sync = job.split("_")[2]
    params = job.split("_")[3]

    gpu_active = []

    for gpu_idx in range(NUM_OF_GPUS):
        # gpu_mem_used.append(data.where[(data['Dataset'] == dataset)
        #                     & (data['Model'] == model)
        #                     & (data['syncronization'] == sync)
        #                     & (data['hyperparameter'] == params)
        #                     & (data['w_idx'] == 1)]['GPU_Memory(MB)'])
        gpu_active.append(data.loc[(data['Dataset'] == dataset)
                                       & (data['Model'] == model)
                                       & (data['syncronization'] == sync)
                                       & (data['hyperparameter'] == params)
                                       & (data['w_idx'] == 1)]['GPU_Active(ms)'].item())

    return gpu_active


def find_gpu_idle(job, data):
    dataset = job.split("_")[0]
    model = job.split("_")[1]
    sync = job.split("_")[2]
    params = job.split("_")[3]

    gpu_idle = []

    for gpu_idx in range(NUM_OF_GPUS):
        # gpu_mem_used.append(data.where[(data['Dataset'] == dataset)
        #                     & (data['Model'] == model)
        #                     & (data['syncronization'] == sync)
        #                     & (data['hyperparameter'] == params)
        #                     & (data['w_idx'] == 1)]['GPU_Memory(MB)'])
        gpu_idle.append(data.loc[(data['Dataset'] == dataset)
                                       & (data['Model'] == model)
                                       & (data['syncronization'] == sync)
                                       & (data['hyperparameter'] == params)
                                       & (data['w_idx'] == 1)]['GPU_Idle(ms)'].item())

    return gpu_idle


def find_gpu_util(job, data):
    dataset = job.split("_")[0]
    model = job.split("_")[1]
    sync = job.split("_")[2]
    params = job.split("_")[3]

    gpu_util = []

    for gpu_idx in range(NUM_OF_GPUS):
        # gpu_mem_used.append(data.where[(data['Dataset'] == dataset)
        #                     & (data['Model'] == model)
        #                     & (data['syncronization'] == sync)
        #                     & (data['hyperparameter'] == params)
        #                     & (data['w_idx'] == 1)]['GPU_Memory(MB)'])
        gpu_util.append(data.loc[(data['Dataset'] == dataset)
                                       & (data['Model'] == model)
                                       & (data['syncronization'] == sync)
                                       & (data['hyperparameter'] == params)
                                       & (data['w_idx'] == 1)]['GPU_Util(%)'].item())

    return gpu_util


def concur_exec_fifo(job_q, slot, cur_gpu_mem, cur_gpu_active, cur_gpu_idle):
    # proc = subprocess.Popen("bash random_job_scripts/" + str(slot) + "_" + job_q[0] + ".sh", shell=True,
    #                     executable="/bin/bash",
    #                     stderr=subprocess.PIPE,
    #                     encoding='utf-8')
    if len(job_q) <= 0:
        return

    job = ""

    # corelog parse result
    parse_result = import_results()

    # check cur_gpu_mem
    print("-----sched start----------")
    print(cur_gpu_mem)

    job_select_lock.acquire()
    job = job_q[0]
    job_gpu_mem = find_gpu_mem_used(job, parse_result)
    # remove selected job from job_q
    job_q.remove(job)
    job_select_lock.release()

    # oom check
    check_lock.acquire()
    oom = False
    for gpu_idx in range(NUM_OF_GPUS):
        if cur_gpu_mem[gpu_idx] + job_gpu_mem[gpu_idx] > GPU_MEM_CAP:
            oom = True
    if oom is True:
        print("oom!job:",job)
        while oom is True:
            sleep(1)
            for gpu_idx in range(NUM_OF_GPUS):
                if cur_gpu_mem[gpu_idx] + job_gpu_mem[gpu_idx] < GPU_MEM_CAP:
                    oom = False

    # update
    update_lock.acquire()
    for gpu_idx in range(NUM_OF_GPUS):
        cur_gpu_mem[gpu_idx] = cur_gpu_mem[gpu_idx] + job_gpu_mem[gpu_idx]
    # find job's gpu_active & gpu_idle and update
    job_gpu_active = find_gpu_active(job, parse_result)
    job_gpu_idle = find_gpu_idle(job, parse_result)
    cur_gpu_active[slot] = job_gpu_active[0]
    cur_gpu_idle[slot] = job_gpu_idle[0]
    update_lock.release()
    check_lock.release()

    print(cur_gpu_mem)

    # launch(start) job through shell
    job_start_time = datetime.datetime.now()
    print("DDL START. slot:", slot+1, "job_q len:", len(job_q), "job:", job)

    proc = subprocess.Popen("bash random_job_scripts/" + str(slot+1) + "_" + job + ".sh", shell=True,
                        executable="/bin/bash",
                        stderr=subprocess.PIPE,
                        encoding='utf-8')
    ret_w = proc.wait()

    job_end_time = datetime.datetime.now()
    job_diff = job_end_time - job_start_time
    print("job start-end secs:", job, job_diff.seconds)
    print("job start-end msecs:", job, job_diff.microseconds)
    print("DDL END. slot:", slot+1, "job_q len:", len(job_q))
    print(ret_w)

    # update gpu_mem after job's end
    job_gpu_mem = find_gpu_mem_used(job, parse_result)

    update_lock.acquire()
    for gpu_idx in range(NUM_OF_GPUS):
        cur_gpu_mem[gpu_idx] = cur_gpu_mem[gpu_idx] - job_gpu_mem[gpu_idx]
    print(cur_gpu_mem)
    cur_gpu_active[slot] = 0
    cur_gpu_idle[slot] = 0
    update_lock.release()

    # ----- 0325 add ----- #
    # if waiting is True:
    #     while waiting is False:
    #         pass
    # ----- 0325 add ----- #


    # schedule next job
    if len(job_q) > 0:
        return concur_exec_fifo(job_q, slot, cur_gpu_mem, cur_gpu_active, cur_gpu_idle)

    return


def get_arguments():
    parser = argparse.ArgumentParser()
    parser.add_argument('--num_of_slot', type=int, default=2, help='an integer for printing repeatably')
    parser.add_argument('--num_of_job', type=int, default=10, help='an integer for printing repeatably')
    parser.add_argument('--execution', type=str, default="fifo", help='an integer for printing repeatably')
    parser.add_argument('--job_Q', type=str, nargs='*', help='an string for printing repeatably')
    parser.add_argument('--save_file', type=str, default="save.csv", help='an string for printing repeatably')

    args = parser.parse_args()

    return args


if __name__ == '__main__':
    args = get_arguments()

    num_of_slot = args.num_of_slot
    num_of_job = args.num_of_job

    cur_gpu_mem = [0 for _ in range(NUM_OF_GPUS)]
    cur_gpu_active = [0 for _ in range(num_of_slot)]
    cur_gpu_idle = [0 for _ in range(num_of_slot)]

    job_q = args.job_Q


    # # generate random jobs
    # for _ in range(0, num_of_job):
    #     job_q.append(generate_scripts())

    print(job_q)

    job_select_lock = threading.Lock()
    check_lock = threading.Lock()
    update_lock = threading.Lock()

    t1 = threading.Thread(target=concur_exec_fifo, args=(job_q, 0, cur_gpu_mem, cur_gpu_active, cur_gpu_idle))
    t2 = threading.Thread(target=concur_exec_fifo, args=(job_q, 1, cur_gpu_mem, cur_gpu_active, cur_gpu_idle))

    # record start time
    start_time = datetime.datetime.now()
    print("start:", start_time)

    t1.start()
    t2.start()

    t1.join()
    t2.join()

    # record end time
    end_time = datetime.datetime.now()
    print("end:", end_time)

    # print end-start time
    diff = end_time - start_time

    print("start-end secs:", diff.seconds)
    print("start-end msecs:", diff.microseconds)
    print("FINISH")



