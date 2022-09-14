import os
import subprocess
import asyncio
import argparse
import math
import csv
import pandas as pd
import datetime
from job_generator import generate_scripts

NUM_OF_GPUS = 2
GPU_MEM_CAP = 30000


def import_results():
    file_path = "2080tiPS2W2_results.csv"
    data = pd.read_csv(file_path,
                       thousands=',',
                       index_col=False,
                       encoding='utf-8')

    return data


def scoring_1st(slot, cur_gpu_active, cur_gpu_idle, job_gpu_active, job_gpu_idle):
    if slot == 0:
        cur_slot = 1
    elif slot == 1:
        cur_slot = 0

    crit_a = abs(cur_gpu_active[cur_slot] - job_gpu_idle)
    crit_b = abs(cur_gpu_idle[cur_slot] - job_gpu_active)

    return crit_a + crit_b


def scoring_2nd(slot, cur_gpu_active, cur_gpu_idle, job_gpu_active, job_gpu_idle):
    if slot == 0:
        cur_slot = 1
    elif slot == 1:
        cur_slot = 0

    score = abs(cur_gpu_idle[cur_slot] - job_gpu_active)

    return score


def scoring_3rd(slot, cur_gpu_active, cur_gpu_idle, job_gpu_active, job_gpu_idle):
    if slot == 0:
        cur_slot = 1
    elif slot == 1:
        cur_slot = 0

    crit_a = cur_gpu_active[cur_slot] / cur_gpu_idle[cur_slot]
    crit_b = job_gpu_active / job_gpu_idle
    score = abs((crit_a * crit_b) - 1)

    return score


def scoring_4th(slot, cur_gpu_active, cur_gpu_idle, job_gpu_active, job_gpu_idle):
    if slot == 0:
        cur_slot = 1
    elif slot == 1:
        cur_slot = 0

    score = abs(cur_gpu_active[cur_slot] - job_gpu_idle)

    return score


def scoring_5th(slot, cur_gpu_active, cur_gpu_idle, job_gpu_active, job_gpu_idle):
    if slot == 0:
        cur_slot = 1
    elif slot == 1:
        cur_slot = 0

    n_cur_gpu_active = cur_gpu_active[cur_slot] / (cur_gpu_idle[cur_slot] + cur_gpu_active[cur_slot])
    n_cur_gpu_idle = cur_gpu_idle[cur_slot] / (cur_gpu_idle[cur_slot] + cur_gpu_active[cur_slot])
    n_job_gpu_active = job_gpu_active / (job_gpu_idle + job_gpu_active)
    n_job_gpu_idle = job_gpu_idle / (job_gpu_idle + job_gpu_active)

    crit_a = n_cur_gpu_active - n_job_gpu_idle
    crit_b = n_cur_gpu_idle - n_job_gpu_active

    return abs(crit_a + crit_b)


def scoring_6th(slot, cur_gpu_active, cur_gpu_idle, job_gpu_active, job_gpu_idle):
    if slot == 0:
        cur_slot = 1
    elif slot == 1:
        cur_slot = 0

    crit_a = cur_gpu_active[cur_slot] / cur_gpu_idle[cur_slot]
    crit_b = job_gpu_active / job_gpu_idle
    crit_c = crit_a * crit_b
    if crit_c > 1:
        score = (crit_a * crit_b) - 1
    else:
        score = (1/(crit_a * crit_b)) - 1

    return score


def scoring_7th(slot, cur_gpu_active, cur_gpu_idle, job_gpu_active, job_gpu_idle):
    if slot == 0:
        cur_slot = 1
    elif slot == 1:
        cur_slot = 0

    crit_a = cur_gpu_active[cur_slot] / cur_gpu_idle[cur_slot]
    crit_b = job_gpu_active / job_gpu_idle

    score = abs(math.log((crit_a * crit_b)))

    return score


def scoring_8th(slot, cur_gpu_active, cur_gpu_idle, job_gpu_active, job_gpu_idle):
    if slot == 0:
        cur_slot = 1
    elif slot == 1:
        cur_slot = 0

    crit_a = cur_gpu_active[cur_slot] / cur_gpu_idle[cur_slot]
    crit_b = job_gpu_active / job_gpu_idle

    log_a = math.log(crit_a) + 0.4
    log_b = math.log(crit_b) + 0.4
    score = abs(2 - log_a - log_b)

    return score


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


def select_job(cur_gpu_mem, job_q, parse_result):
    oom = False
    job = ""

    for idx in range(len(job_q)):
        # oom test
        job_gpu_mem = find_gpu_mem_used(job_q[idx], parse_result)
        for gpu_idx in range(NUM_OF_GPUS):
            if cur_gpu_mem[gpu_idx] + job_gpu_mem[gpu_idx] > GPU_MEM_CAP:
                oom = True
        if oom is False:
            job = job_q[idx]
            break
        else:
            oom = False

    if job == "":
        print("Error!!!!!!!!!!!!!!! Not desired")

    return job, job_gpu_mem


def select_best_job(cur_gpu_mem, cur_gpu_active, cur_gpu_idle, job_q, slot, parse_result):
    oom = False
    job = ""
    score = [9999999999 for _ in range(len(job_q))]

    for idx in range(len(job_q)):
        # oom test
        gpu_mem = find_gpu_mem_used(job_q[idx], parse_result)
        for gpu_idx in range(NUM_OF_GPUS):
            if cur_gpu_mem[gpu_idx] + gpu_mem[gpu_idx] > GPU_MEM_CAP:
                oom = True
        if oom:
            oom = False
        else:
            gpu_active = find_gpu_active(job_q[idx], parse_result)
            gpu_idle = find_gpu_idle(job_q[idx], parse_result)
            score[idx] \
                = scoring_8th(slot, cur_gpu_active, cur_gpu_idle, gpu_active[1], gpu_idle[1])

    job = job_q[score.index(min(score))]
    job_gpu_mem = find_gpu_mem_used(job, parse_result)
    job_gpu_active = find_gpu_active(job, parse_result)
    job_gpu_idle = find_gpu_active(job, parse_result)

    if job == "":
        print("Error!!!!!!!!!!!!!!! Not desired")

    return job, job_gpu_mem, job_gpu_active, job_gpu_idle


async def concur_exec_fifo(job_q, slot, cur_gpu_mem, cur_gpu_active, cur_gpu_idle):
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

    if sum(cur_gpu_mem) == 0:
        # when init scheduling, select first job from job_q
        job, job_gpu_mem = select_job(cur_gpu_mem, job_q, parse_result)

        # remove selected job from job_q
        job_q.remove(job)

        # selected job's gpu_mem update
        for gpu_idx in range(NUM_OF_GPUS):
            cur_gpu_mem[gpu_idx] = cur_gpu_mem[gpu_idx] + job_gpu_mem[gpu_idx]

        # find job's gpu_active & gpu_idle and update
        job_gpu_active = find_gpu_active(job, parse_result)
        job_gpu_idle = find_gpu_idle(job, parse_result)
        cur_gpu_active[slot] = job_gpu_active[0]
        cur_gpu_idle[slot] = job_gpu_idle[0]
    else:
        # when init scheduling, select first job from job_q
        job, job_gpu_mem\
            = select_job(cur_gpu_mem, job_q, parse_result)

        # remove selected job from job_q
        job_q.remove(job)

        # update selected job's gpu_mem
        for gpu_idx in range(NUM_OF_GPUS):
            cur_gpu_mem[gpu_idx] = cur_gpu_mem[gpu_idx] + job_gpu_mem[gpu_idx]

        # update gpu_active & gpu_idle and update
        job_gpu_active = find_gpu_active(job, parse_result)
        job_gpu_idle = find_gpu_idle(job, parse_result)
        cur_gpu_active[slot] = job_gpu_active[0]
        cur_gpu_idle[slot] = job_gpu_idle[0]

    # check cur_gpu_mem
    print(cur_gpu_mem)

    # launch(start) job through shell
    job_start_time = datetime.datetime.now()
    print("DDL START. slot:", slot+1, "job_q len:", len(job_q), "job:", job)
    # proc = await asyncio.create_subprocess_shell("bash random_job_scripts/" + str(slot) + "_" + job + ".sh",
    #                                        shell=True,
    #                                        executable="/bin/bash",
    #                                        stderr=subprocess.PIPE,
    #                                        encoding='utf-8')
    proc = await asyncio.create_subprocess_shell("bash random_job_scripts/" + str(slot+1) + "_" + job + ".sh",
                                                 shell=True,
                                                 executable="/bin/bash",
                                                 encoding='utf-8')
    ret_w = await proc.wait()

    job_end_time = datetime.datetime.now()
    job_diff = job_end_time - job_start_time
    print("job start-end secs:", job, job_diff.seconds)
    print("job start-end msecs:", job, job_diff.microseconds)
    print("DDL END. slot:", slot+1, "job_q len:", len(job_q))
    print(ret_w)

    # update gpu_mem after job's end
    job_gpu_mem = find_gpu_mem_used(job, parse_result)
    for gpu_idx in range(NUM_OF_GPUS):
        cur_gpu_mem[gpu_idx] = cur_gpu_mem[gpu_idx] - job_gpu_mem[gpu_idx]
    print(cur_gpu_mem)

    # schedule next job
    if len(job_q) > 0:
        return await concur_exec_fifo(job_q, slot, cur_gpu_mem, cur_gpu_active, cur_gpu_idle)

    return


async def concur_exec_xonar(job_q, slot, cur_gpu_mem, cur_gpu_active, cur_gpu_idle):
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

    if sum(cur_gpu_mem) == 0:
        # when init scheduling, select first job from job_q
        job, job_gpu_mem = select_job(cur_gpu_mem, job_q, parse_result)

        # remove selected job from job_q
        job_q.remove(job)

        # selected job's gpu_mem update
        for gpu_idx in range(NUM_OF_GPUS):
            cur_gpu_mem[gpu_idx] = cur_gpu_mem[gpu_idx] + job_gpu_mem[gpu_idx]

        # find job's gpu_active & gpu_idle and update
        job_gpu_active = find_gpu_active(job, parse_result)
        job_gpu_idle = find_gpu_idle(job, parse_result)
        cur_gpu_active[slot] = job_gpu_active[0]
        cur_gpu_idle[slot] = job_gpu_idle[0]
    else:
        # when init scheduling, select first job from job_q
        job, job_gpu_mem, job_gpu_active, job_gpu_idle \
            = select_best_job(cur_gpu_mem, cur_gpu_active, cur_gpu_idle, job_q, slot, parse_result)

        # remove selected job from job_q
        job_q.remove(job)

        # update selected job's gpu_mem
        for gpu_idx in range(NUM_OF_GPUS):
            cur_gpu_mem[gpu_idx] = cur_gpu_mem[gpu_idx] + job_gpu_mem[gpu_idx]

        # update gpu_active & gpu_idle and update
        cur_gpu_active[slot] = job_gpu_active[0]
        cur_gpu_idle[slot] = job_gpu_idle[0]

    # check cur_gpu_mem
    print(cur_gpu_mem)

    # launch(start) job through shell
    job_start_time = datetime.datetime.now()
    print("DDL START. slot:", slot+1, "job_q len:", len(job_q), "job:", job)
    # proc = await asyncio.create_subprocess_shell("bash random_job_scripts/" + str(slot) + "_" + job + ".sh",
    #                                        shell=True,
    #                                        executable="/bin/bash",
    #                                        stderr=subprocess.PIPE,
    #                                        encoding='utf-8')
    proc = await asyncio.create_subprocess_shell("bash random_job_scripts/" + str(slot+1) + "_" + job + ".sh",
                                                 shell=True,
                                                 executable="/bin/bash",
                                                 encoding='utf-8')
    ret_w = await proc.wait()
    job_end_time = datetime.datetime.now()
    job_diff = job_end_time - job_start_time
    print("job start-end secs:", job, job_diff.seconds)
    print("job start-end msecs:", job, job_diff.microseconds)
    print("DDL END. slot:", slot+1, "job_q len:", len(job_q))
    print(ret_w)

    # update gpu_mem after job's end
    job_gpu_mem = find_gpu_mem_used(job, parse_result)
    for gpu_idx in range(NUM_OF_GPUS):
        cur_gpu_mem[gpu_idx] = cur_gpu_mem[gpu_idx] - job_gpu_mem[gpu_idx]
    print(cur_gpu_mem)

    # schedule next job
    if len(job_q) > 0:
        return await concur_exec_xonar(job_q, slot, cur_gpu_mem, cur_gpu_active, cur_gpu_idle)

    return


def select_slot1_job(cur_gpu_mem, cur_gpu_active, cur_gpu_idle, job_q, slot, parse_result):
    oom = False
    job = ""
    gpu_active_list = [0 for _ in range(len(job_q))]

    for idx in range(len(job_q)):
        # oom test
        gpu_mem = find_gpu_mem_used(job_q[idx], parse_result)
        for gpu_idx in range(NUM_OF_GPUS):
            if cur_gpu_mem[gpu_idx] + gpu_mem[gpu_idx] > GPU_MEM_CAP:
                oom = True
        if oom:
            oom = False
        else:
            gpu_active = find_gpu_active(job_q[idx], parse_result)
            gpu_idle = find_gpu_idle(job_q[idx], parse_result)
            # gpu_util = find_gpu_util(job_q[idx], parse_result)
            # gpu_active_list[idx] = gpu_util
            gpu_active_list[idx] = gpu_active[0] / gpu_idle[0]
            # gpu_active_list[idx] = gpu_active[0] - gpu_idle[0]

    job = job_q[gpu_active_list.index(max(gpu_active_list))]
    job_gpu_mem = find_gpu_mem_used(job, parse_result)
    job_gpu_active = find_gpu_active(job, parse_result)
    job_gpu_idle = find_gpu_active(job, parse_result)

    if job == "":
        print("Error!!!!!!!!!!!!!!! Not desired")

    return job, job_gpu_mem, job_gpu_active, job_gpu_idle


def select_slot2_job(cur_gpu_mem, cur_gpu_active, cur_gpu_idle, job_q, slot, parse_result):
    oom = False
    job = ""
    gpu_active_list = [99999999999 for _ in range(len(job_q))]

    for idx in range(len(job_q)):
        # oom test
        gpu_mem = find_gpu_mem_used(job_q[idx], parse_result)
        for gpu_idx in range(NUM_OF_GPUS):
            if cur_gpu_mem[gpu_idx] + gpu_mem[gpu_idx] > GPU_MEM_CAP:
                oom = True
        if oom:
            oom = False
        else:
            gpu_active = find_gpu_active(job_q[idx], parse_result)
            gpu_idle = find_gpu_idle(job_q[idx], parse_result)
            # gpu_util = find_gpu_util(job_q[idx], parse_result)
            # gpu_active_list[idx] = gpu_util
            gpu_active_list[idx] = gpu_active[0] / gpu_idle[0]
            # gpu_active_list[idx] = gpu_active[0] - gpu_idle[0]

    job = job_q[gpu_active_list.index(min(gpu_active_list))]
    job_gpu_mem = find_gpu_mem_used(job, parse_result)
    job_gpu_active = find_gpu_active(job, parse_result)
    job_gpu_idle = find_gpu_active(job, parse_result)

    if job == "":
        print("Error!!!!!!!!!!!!!!! Not desired")

    return job, job_gpu_mem, job_gpu_active, job_gpu_idle


async def concur_exec_xonarnew(job_q, slot, cur_gpu_mem, cur_gpu_active, cur_gpu_idle):
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

    # when init scheduling, select first job from job_q
    if slot is 0:
        job, job_gpu_mem, job_gpu_active, job_gpu_idle \
            = select_slot1_job(cur_gpu_mem, cur_gpu_active, cur_gpu_idle, job_q, slot, parse_result)
    elif slot is 1:
        job, job_gpu_mem, job_gpu_active, job_gpu_idle \
            = select_slot2_job(cur_gpu_mem, cur_gpu_active, cur_gpu_idle, job_q, slot, parse_result)

    # remove selected job from job_q
    job_q.remove(job)

    # update selected job's gpu_mem
    for gpu_idx in range(NUM_OF_GPUS):
        cur_gpu_mem[gpu_idx] = cur_gpu_mem[gpu_idx] + job_gpu_mem[gpu_idx]

    # update gpu_active & gpu_idle and update
    cur_gpu_active[slot] = job_gpu_active[0]
    cur_gpu_idle[slot] = job_gpu_idle[0]

    # check cur_gpu_mem
    print(cur_gpu_mem)

    # launch(start) job through shell
    job_start_time = datetime.datetime.now()
    print("DDL START. slot:", slot+1, "job_q len:", len(job_q), "job:", job)
    # proc = await asyncio.create_subprocess_shell("bash random_job_scripts/" + str(slot) + "_" + job + ".sh",
    #                                        shell=True,
    #                                        executable="/bin/bash",
    #                                        stderr=subprocess.PIPE,
    #                                        encoding='utf-8')
    proc = await asyncio.create_subprocess_shell("bash random_job_scripts/" + str(slot+1) + "_" + job + ".sh",
                                                 shell=True,
                                                 executable="/bin/bash",
                                                 encoding='utf-8')
    ret_w = await proc.wait()
    job_end_time = datetime.datetime.now()
    job_diff = job_end_time - job_start_time
    print("job start-end secs:", job, job_diff.seconds)
    print("job start-end msecs:", job, job_diff.microseconds)
    print("DDL END. slot:", slot+1, "job_q len:", len(job_q))
    print(ret_w)

    # update gpu_mem after job's end
    job_gpu_mem = find_gpu_mem_used(job, parse_result)
    for gpu_idx in range(NUM_OF_GPUS):
        cur_gpu_mem[gpu_idx] = cur_gpu_mem[gpu_idx] - job_gpu_mem[gpu_idx]
    print(cur_gpu_mem)

    # schedule next job
    if len(job_q) > 0:
        return await concur_exec_xonarnew(job_q, slot, cur_gpu_mem, cur_gpu_active, cur_gpu_idle)

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

    # ready jobs in each slot
    if num_of_slot == 1:
        jobs = [concur_exec_xonar(job_q, slot, cur_gpu_mem, cur_gpu_active, cur_gpu_idle) for slot in range(num_of_slot)]
    elif args.execution == "fifo":
        jobs = [concur_exec_fifo(job_q, slot, cur_gpu_mem, cur_gpu_active, cur_gpu_idle) for slot in range(num_of_slot)]
    elif args.execution == "xonar":
        jobs = [concur_exec_xonar(job_q, slot, cur_gpu_mem, cur_gpu_active, cur_gpu_idle) for slot in range(num_of_slot)]
    elif args.execution == "xonarnew":
        jobs = [concur_exec_xonarnew(job_q, slot, cur_gpu_mem, cur_gpu_active, cur_gpu_idle) for slot in range(num_of_slot)]

    # record start time
    start_time = datetime.datetime.now()
    print("start:", start_time)

    # start job scheduling
    loop = asyncio.get_event_loop()  # 이벤트 루프를 얻음
    loop.run_until_complete(asyncio.wait(jobs))  # main이 끝날 때까지 기다림
    loop.close()

    # record end time
    end_time = datetime.datetime.now()
    print("end:", end_time)

    # print end-start time
    diff = end_time - start_time

    print("start-end secs:", diff.seconds)
    print("start-end msecs:", diff.microseconds)

    print("FINISH")

