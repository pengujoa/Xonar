import os
import json
import sys
import pandas as pd
NUM_OF_GPUS = 2

def parse_s(log_lines, gpu_file, job_list, not_desired):
    # not_desired
    if not_desired is True:
        return 0, 0, 0, 0, not_desired
    for line in log_lines:
        if "Not desired" in line:
            not_desired = True
            return 0, 0, 0, 0, not_desired

    # job_jct & job_exec_order
    job_jct = {}
    job_exec_order = []
    for i in range(len(job_list)):
        job_jct[job_list[i]] = 0

    for line in log_lines:
        if "DDL START. slot" in line:
            job = line.split(" ")[8]
            job_exec_order.append(job)
        if "job start-end secs" in line:
            job = line.split(" ")[3]
            sec = int(line.split(" ")[4])
            job_jct[job] = job_jct[job] + sec
        if "job start-end msecs" in line:
            job = line.split(" ")[3]
            msec = int(line.split(" ")[4])
            job_jct[job] = job_jct[job] + (msec/1000000)

    # jct
    sec = int(log_lines[-4].split(" ")[2])
    msec = int(log_lines[-3].split(" ")[2])
    # sec = 0
    # msec = 0
    # for line in log_lines:
    #     if "start-end secs" in line:
    #         sec = int(line.split(" ")[2])
    #     if "start-end msecs" in line:
    #         msec = int(line.split(" ")[2])
    jct = sec + (msec/1000000)

    # gpu util
    gpu_lines = gpu_file.read().split("\n")
    gpu_lines.pop()
    gpu_util = 0
    for line in gpu_lines:
        val = int(line.split(" ")[-8])
        gpu_util = gpu_util + val
    gu = gpu_util / len(gpu_lines)

    return jct, gu, job_jct, job_exec_order, not_desired


def parse(log_file, gpu_file, job_list, not_desired):
    log_lines = log_file.read().split("\n")
    oom_delayed = 0
    for line in log_lines:
        if "oom" in line:
            oom_delayed = oom_delayed + 1

    # not_desired
    if not_desired is True:
        return 0, 0, 0, 0, not_desired, oom_delayed
    for line in log_lines:
        if "Not desired" in line:
            not_desired = True
            return 0, 0, 0, 0, not_desired, oom_delayed


    # job_jct & job_exec_order
    job_jct = {}
    job_exec_order = []
    for i in range(len(job_list)):
        job_jct[job_list[i]] = 0

    for line in log_lines:
        if "DDL START. slot" in line:
            job = line.split(" ")[8]
            job_exec_order.append(job)
        if "job start-end secs" in line:
            job = line.split(" ")[3]
            sec = int(line.split(" ")[4])
            job_jct[job] = job_jct[job] + sec
        if "job start-end msecs" in line:
            job = line.split(" ")[3]
            msec = int(line.split(" ")[4])
            job_jct[job] = job_jct[job] + (msec/1000000)

    # jct
    sec = int(log_lines[-4].split(" ")[2])
    msec = int(log_lines[-3].split(" ")[2])
    # sec = 0
    # msec = 0
    # for line in log_lines:
    #     if "start-end secs" in line:
    #         sec = int(line.split(" ")[2])
    #     if "start-end msecs" in line:
    #         msec = int(line.split(" ")[2])

    jct = sec + (msec/1000000)

    # gpu util
    gpu_lines = gpu_file.read().split("\n")
    gpu_lines.pop()
    gpu_util = 0
    for line in gpu_lines:
        val = int(line.split(" ")[-8])
        gpu_util = gpu_util + val
    gu = gpu_util / len(gpu_lines)

    return jct, gu, job_jct, job_exec_order, not_desired, oom_delayed


def find_profile_results(job, data):
    dataset = job.split("_")[0]
    model = job.split("_")[1]
    sync = job.split("_")[2]
    params = job.split("_")[3]

    gpu_active = []
    gpu_idle = []

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
        gpu_idle.append(data.loc[(data['Dataset'] == dataset)
                                       & (data['Model'] == model)
                                       & (data['syncronization'] == sync)
                                       & (data['hyperparameter'] == params)
                                       & (data['w_idx'] == 1)]['GPU_Idle(ms)'].item())

    return gpu_active, gpu_idle


def parse_trace(log_file, gpu_file, job_list, not_desired, trial_idx, trace):
    file_path = "v100PS2W2_results_wogroupdeps_gpuutil.csv"
    data = pd.read_csv(file_path,
                       thousands=',',
                       index_col=False,
                       encoding='utf-8')

    log_lines = log_file.read().split("\n")
    # not_desired
    if not_desired is True:
        return 0, 0, 0, 0, not_desired
    for line in log_lines:
        if "Not desired" in line:
            not_desired = True
            return 0, 0, 0, 0, not_desired

    # job_jct & job_exec_order
    job_jct = {}
    job_exec_order = []
    slot_exec_order = []
    slot_1_ts = 1
    slot_2_ts = 1

    for i in range(len(job_list)):
        job_jct[job_list[i]] = 0

    for line in log_lines:
        if "DDL START. slot" in line:
            job = line.split(" ")[8]
            job_exec_order.append(job)
            slot = line.split(" ")[3]
            slot_exec_order.append(slot)
        if "job start-end secs" in line:
            job = line.split(" ")[3]
            sec = int(line.split(" ")[4])
            job_jct[job] = job_jct[job] + sec
        if "job start-end msecs" in line:
            job = line.split(" ")[3]
            msec = int(line.split(" ")[4])
            job_jct[job] = job_jct[job] + (msec/1000000)

    for i in range(len(job_list)):
        job = job_exec_order[i]
        gpu_active, gpu_idle = find_profile_results(job, data)
        slot = int(slot_exec_order[i])
        ts = 0
        if slot == 1:
            ts = slot_1_ts
            slot_1_ts = slot_1_ts + job_jct[job]-1
        elif slot == 2:
            ts = slot_2_ts
            slot_2_ts = slot_2_ts + job_jct[job]-1

        trace["traceEvents"].append({"ph": "X","cat": "DDLjob","name": job,"pid": trial_idx,"tid": slot,
                                     "ts": ts,"dur": job_jct[job]-1,
                                     "args": {"name": job,"active": gpu_active[0],"idle": gpu_idle[0],"ratio":gpu_active[0]/gpu_idle[0]}})


    # jct
    sec = int(log_lines[-4].split(" ")[2])
    msec = int(log_lines[-3].split(" ")[2])
    jct = sec + (msec/1000000)

    # gpu util
    gpu_lines = gpu_file.read().split("\n")
    gpu_lines.pop()
    gpu_util = 0
    for line in gpu_lines:
        val = int(line.split(" ")[-8])
        gpu_util = gpu_util + val
    gu = gpu_util / len(gpu_lines)

    return jct, gu, job_jct, job_exec_order, not_desired


folder = "final/new"
sys.stdout = open('stdout.txt', 'w')

job_num = range(1,51)

# job_num = [11,31, 55, 59]

trace = {"traceEvents":[]}

oom_delayed_count = 0
oom = 0

for idx in job_num:
    job_list = []

    not_desired = False

    log_file_s = open(folder + "/" + "log_single_fifo_" + str(idx) + ".txt", "r")
    # log_file_s = open(folder + "/" + "log_concur_fifo_" + str(idx) + ".txt", "r")
    log_file_c_f = open(folder + "/" + "log_concur_fifo_" + str(idx) + ".txt", "r")
    # log_file_c_f = open(folder + "/" + "log_concur_xonarnew_" + str(idx) + ".txt", "r")
    log_file_c_x = open(folder + "/" + "log_concur_xonar_" + str(idx) + ".txt", "r")
    # log_file_c_x = open(folder + "/" + "log_concur_fifo_" + str(idx) + ".txt", "r")

    gpu_file_s = open(folder + "/" + "gpu_single_fifo_" + str(idx) + ".txt", "r")
    # gpu_file_s = open(folder + "/" + "gpu_concur_fifo_" + str(idx) + ".txt", "r")
    gpu_file_c_f = open(folder + "/" + "gpu_concur_fifo_" + str(idx) + ".txt", "r")
    # gpu_file_c_f = open(folder + "/" + "gpu_concur_xonarnew_" + str(idx) + ".txt", "r")
    gpu_file_c_x = open(folder + "/" + "gpu_concur_xonar_" + str(idx) + ".txt", "r")
    # gpu_file_c_x = open(folder + "/" + "gpu_concur_fifo_" + str(idx) + ".txt", "r")

    log_lines = log_file_s.read().split("\n")
    job_string = max(log_lines, key=len)
    job_string = job_string.strip("[""]")
    job_string = job_string.replace("'", "")
    job_string = job_string.replace(" ", "")
    job_list = job_string.split(",")
    job_list.sort()

    trace["traceEvents"].append({"name": "process_name","ph": "M","pid": idx,"args": {"name": "trial_"+str(idx)}})

    # job_list = ["a","b","c","d","e","f","g","h","i","j"]

    # c_f_jct, c_f_gu, c_f_job_jct, c_f_job_exec_order, not_desired = parse_trace(log_file_c_f, gpu_file_c_f, job_list,
    #                                                                       not_desired, idx, trace)

    s_jct, s_gu, s_job_jct, s_job_exec_order, not_desired = parse_s(log_lines, gpu_file_s, job_list, not_desired)
    c_x_jct, c_x_gu, c_x_job_jct, c_x_job_exec_order, not_desired, oom_delayed = parse(log_file_c_x, gpu_file_c_x, job_list, not_desired)
    c_f_jct, c_f_gu, c_f_job_jct, c_f_job_exec_order, not_desired, oom_delayed = parse(log_file_c_f, gpu_file_c_f, job_list, not_desired)

    if oom_delayed > 0:
        # if not_desired is False:
        # print(oom_delayed_count)
        oom = oom + 1
        oom_delayed_count = oom_delayed_count + oom_delayed
        print(oom_delayed, idx)

    if not_desired:
        # print("num:", idx)
        # print("single_exec: not_desired")
        # print("concur_exec_fifo: not_desired")
        # print("concur_exec_xonar: not_desired")
        # print()
        # print()
        pass
    else:
        pass
        # print("num:", idx, end=" ")
        # for job_idx in range(0, 10):
        #     print(job_list[job_idx], end=" ")
        # print()
        #
        # print("single_exec:", s_jct, s_gu, end=" ")
        # for job_idx in range(0, 10):
        #     print(s_job_jct[job_list[job_idx]], end=" ")
        # for job_idx in range(0, 10):
        #     print(s_job_exec_order[job_idx], end=" ")
        # print()
        #
        # print("concur_exec_fifo:", c_f_jct, c_f_gu, end=" ")
        # for job_idx in range(0, 10):
        #     print(c_f_job_jct[job_list[job_idx]], end=" ")
        # for job_idx in range(0, 10):
        #     print(c_f_job_exec_order[job_idx], end=" ")
        # print()
        #
        # print("concur_exec_xonar:", c_x_jct, c_x_gu, end=" ")
        # for job_idx in range(0, 10):
        #     print(c_x_job_jct[job_list[job_idx]], end=" ")
        # for job_idx in range(0, 10):
        #     print(c_x_job_exec_order[job_idx], end=" ")
        # print()
        #
        # print()
        # print()

    # 10_final.sh
    # print("jobq=\"", end="")
    # for job_idx in range(0, 9):
    #     print(job_list[job_idx], end=" ")
    # print(job_list[9],end="")
    # print("\"")
    # print("i="+str(idx))
    # print("nohup /home/ubuntu/cyshin/benchmarks/jhtest/NVML > /home/ubuntu/cyshin/benchmarks/xonar_sim/results/gpu_concur_fifo_"+str(idx)+".txt &")
    # print("python scheduler_fifo.py --num_of_slot=2 --num_of_job=10 --execution=\"fifo\" --job_Q $jobq > results/log_concur_fifo_"+str(idx)+".txt")
    # print("sudo pkill NVML")
    # print("sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;")
    # print()

print(oom_delayed_count)
print(oom)

sys.stdout.close()

# sys.stdout = open('jct_variance5.json', 'w')
# print(json.dumps(trace, indent=4))
# sys.stdout.close()






