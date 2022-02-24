import os
import subprocess
import asyncio
import csv
import pandas as pd
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


def scoring(GPU, cur_job, cmp_job):

    return


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


def find_job(cur_gpu_mem, job_q, parse_result):
    selected = False
    job = ""
    for idx in range(len(job_q)):
        job_mem = find_gpu_mem_used(job_q[idx], parse_result)
        for gpu_idx in range(NUM_OF_GPUS):
            if cur_gpu_mem[gpu_idx] + job_mem[gpu_idx] < GPU_MEM_CAP:
                selected = True
            if selected == False:
                break
        if selected == True:
            job = job_q[idx]
            break

    if job == "":
        print("Error!!!!!!!!!!!!!!! Not desired")

    return job, job_mem


async def schedule(job_q, slot, cur_gpu_mem):
    # proc = subprocess.Popen("bash random_job_scripts/" + str(slot) + "_" + job_q[0] + ".sh", shell=True,
    #                     executable="/bin/bash",
    #                     stderr=subprocess.PIPE,
    #                     encoding='utf-8')
    if len(job_q) <= 0:
        return

    # select job
    parse_result = import_results()

    job, job_mem = find_job(cur_gpu_mem, job_q, parse_result)



    print("-----sched start----------")
    print(cur_gpu_mem)

    for gpu_idx in range(NUM_OF_GPUS):
        cur_gpu_mem[gpu_idx] = cur_gpu_mem[gpu_idx] + job_mem[gpu_idx]

    print(cur_gpu_mem)
    # remove selected job from job_q
    job_q.remove(job)

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


    for gpu_idx in range(NUM_OF_GPUS):
        cur_gpu_mem[gpu_idx] = cur_gpu_mem[gpu_idx] - job_mem[gpu_idx]
    print(cur_gpu_mem)

    if len(job_q) > 0:
        return await schedule(job_q, slot, cur_gpu_mem)

    return


async def main():
    # await asyncio.gather(
    #     schedule(job_q, 1, job_q),
    #     schedule(job_q, 2, job_q)
    # )
    return


if __name__ == '__main__':
    num_of_slot = 2
    num_of_job = 10
    cur_gpu_mem = [0 for _ in range(NUM_OF_GPUS)]
    job_q = []
    for _ in range(0, num_of_job):
        job_q.append(generate_scripts())

    # job_q = ["cifar10_alexnet_sync_batch32", "cifar10_alexnet_sync_batch32", "cifar10_alexnet_sync_batch32",
    #          "cifar10_alexnet_sync_batch32", "cifar10_alexnet_sync_batch32", "cifar10_alexnet_sync_batch32",
    #          "cifar10_alexnet_sync_batch32", "cifar10_alexnet_sync_batch32", "cifar10_alexnet_sync_batch32",
    #          "cifar10_alexnet_sync_batch32"]

    jobs = [schedule(job_q, slot, cur_gpu_mem) for slot in range(num_of_slot)]
    loop = asyncio.get_event_loop()  # 이벤트 루프를 얻음
    loop.run_until_complete(asyncio.wait(jobs))  # main이 끝날 때까지 기다림
    loop.close()
    print("FINISH")
