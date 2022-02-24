import os
import subprocess
import asyncio
import csv
import pandas as pd
import datetime
from job_generator import generate_scripts

NUM_OF_GPUS = 2
GPU_MEM_CAP = 30000


def import_results():
    # file_path = "D:/2021/개인연구/Xonar/git/results/v100PS2W2_results_wogroupdeps.csv"
    file_path = "v100PS2W2_results_wogroupdeps.csv"
    data = pd.read_csv(file_path,
                       thousands=',',
                       index_col=False,
                       encoding='utf-8')

    return data


def scoring(slot, cur_gpu_active, cur_gpu_idle, job_gpu_active, job_gpu_idle):
    if slot == 0:
        cur_slot = 1
    elif slot == 1:
        cur_slot = 0

    score = abs(cur_gpu_idle[cur_slot] - job_gpu_active)

    return score


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

    crit_a = cur_gpu_active[cur_slot] / cur_gpu_idle[cur_slot]
    crit_b = job_gpu_active / job_gpu_idle
    score = abs((crit_a * crit_b) - 1)

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


def select_job(cur_gpu_mem, job_q, parse_result):
    oom = False
    job = ""

    for idx in range(len(job_q)):
        # oom test
        job_gpu_mem = find_gpu_mem_used(job_q[idx], parse_result)
        for gpu_idx in range(NUM_OF_GPUS):
            if cur_gpu_mem[gpu_idx] + job_gpu_mem[gpu_idx] > GPU_MEM_CAP:
                oom = True
                break
        if oom is False:
            job = job_q[idx]
            break

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
                break
        if oom:
            pass
        else:
            gpu_active = find_gpu_active(job_q[idx], parse_result)
            gpu_idle = find_gpu_idle(job_q[idx], parse_result)
            score[idx] \
                = scoring(slot, cur_gpu_active, cur_gpu_idle, gpu_active[0], gpu_idle[0])

    job = job_q[score.index(min(score))]
    job_gpu_mem = find_gpu_mem_used(job, parse_result)
    job_gpu_active = find_gpu_active(job, parse_result)
    job_gpu_idle = find_gpu_active(job, parse_result)

    if job == "":
        print("Error!!!!!!!!!!!!!!! Not desired")

    return job, job_gpu_mem, job_gpu_active, job_gpu_idle


async def schedule_fifo(job_q, slot, cur_gpu_mem, cur_gpu_active, cur_gpu_idle):
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
    print("DDL END. slot:", slot+1, "job_q len:", len(job_q))
    print(ret_w)

    # update gpu_mem after job's end
    job_gpu_mem = find_gpu_mem_used(job, parse_result)
    for gpu_idx in range(NUM_OF_GPUS):
        cur_gpu_mem[gpu_idx] = cur_gpu_mem[gpu_idx] - job_gpu_mem[gpu_idx]
    print(cur_gpu_mem)

    # schedule next job
    if len(job_q) > 0:
        return await schedule_fifo(job_q, slot, cur_gpu_mem, cur_gpu_active, cur_gpu_idle)

    return


async def schedule_score(job_q, slot, cur_gpu_mem, cur_gpu_active, cur_gpu_idle):
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
    print("DDL END. slot:", slot+1, "job_q len:", len(job_q))
    print(ret_w)

    # update gpu_mem after job's end
    job_gpu_mem = find_gpu_mem_used(job, parse_result)
    for gpu_idx in range(NUM_OF_GPUS):
        cur_gpu_mem[gpu_idx] = cur_gpu_mem[gpu_idx] - job_gpu_mem[gpu_idx]
    print(cur_gpu_mem)

    # schedule next job
    if len(job_q) > 0:
        return await schedule_score(job_q, slot, cur_gpu_mem, cur_gpu_active, cur_gpu_idle)

    return


if __name__ == '__main__':
    num_of_slot = 1
    num_of_job = 10

    cur_gpu_mem = [0 for _ in range(NUM_OF_GPUS)]
    cur_gpu_active = [0 for _ in range(num_of_slot)]
    cur_gpu_idle = [0 for _ in range(num_of_slot)]

    job_q = []

    # generate random jobs
    for _ in range(0, num_of_job):
        job_q.append(generate_scripts())

    # job_q = ['cifar10_densenet100k12_sync_batch32', 'cifar10_resnet20v2_sync_batch512', 'cifar10_resnet32v2_async_batch512', 'imagenet_alexnet_async_batch256', 'imagenet_resnet50_sync_dataFormat', 'cifar10_resnet32_async_usefp16', 'imagenet_googlenet_async_batch512', 'cifar10_vgg16_sync_batch256', 'imagenet_inception4_async_winograd', 'cifar10_resnet32v2_async_batch64']
    #job_q = ["imagenet_resnet50_async_optMomentum", "imagenet_resnet50_async_usefp16", "imagenet_resnet50_sync_dataFormat", "imagenet_resnet50v2_async_optMomentum", "imagenet_resnet50v2_sync_batch64", "imagenet_vgg19_sync_batch32", "imagenet_vgg11_async_winograd", "imagenet_vgg19_sync_batch32", "imagenet_vgg11_async_winograd", "imagenet_vgg19_sync_batch32"]
    # job_q = ["imagenet_resnet50_async_optMomentum",  "imagenet_vgg19_sync_batch32",
    #          "imagenet_resnet50_async_usefp16", "imagenet_vgg11_async_winograd",
    #          "imagenet_resnet50_sync_dataFormat", "imagenet_vgg19_sync_batch32",
    #          "imagenet_resnet50v2_async_optMomentum", "imagenet_vgg11_async_winograd",
    #          "imagenet_resnet50v2_sync_batch64", "imagenet_vgg19_sync_batch32"]
    # job_q = ["imagenet_resnet152_async_batch32", "imagenet_vgg19_sync_batch32", "imagenet_resnet152_async_batch32",
    #          "imagenet_vgg19_sync_batch32", "imagenet_resnet152_async_batch32", "imagenet_vgg19_sync_batch32",
    #          "imagenet_resnet152_async_batch32", "imagenet_vgg19_sync_batch32", "imagenet_resnet152_async_batch32",
    #          "imagenet_vgg19_sync_batch32"]
    job_q = ['cifar10_resnet110_async_winograd', 'cifar10_densenet40k12_sync_optMomentum', 'imagenet_vgg11_async_batch64', 'cifar10_resnet32v2_async_xla', 'cifar10_resnet20_sync_optRmsprop', 'cifar10_resnet32v2_sync_winograd', 'imagenet_resnet50_sync_usefp16', 'imagenet_inception3_async_usefp16', 'cifar10_resnet44v2_async_winograd', 'imagenet_overfeat_sync_usefp16']

    print(job_q)

    # ready jobs in each slot
    # jobs = [schedule_score(job_q, slot, cur_gpu_mem, cur_gpu_active, cur_gpu_idle) for slot in range(num_of_slot)]

    jobs = [schedule_fifo(job_q, slot, cur_gpu_mem, cur_gpu_active, cur_gpu_idle) for slot in range(num_of_slot)]

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
