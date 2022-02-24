import os
import subprocess
import asyncio
import csv
import pandas as pd
from job_generator import generate_scripts


def import_results():
    file_path = "D:/2021/개인연구/Xonar/git/results/v100PS2W2_results_gpu.csv"
    # with open(file_path, newline='') as file:
    #     result_reader = csv.reader(file, delimiter=' ', quotechar='|')
    #     for row in result_reader:
    #         print(', '.join(row))

    dat = pd.read_csv(file_path,
                      thousands = ',',
                      index_col = 0,
                      encoding = 'utf-8')

    print(dat.head())

    print(dat.columns)

    return

def scoring(GPU, cur_job, cmp_job):


    return


async def schedule(GPU_Q, slot, job_Q):
    # proc = subprocess.Popen("bash random_job_scripts/" + str(slot) + "_" + job_Q[0] + ".sh", shell=True,
    #                     executable="/bin/bash",
    #                     stderr=subprocess.PIPE,
    #                     encoding='utf-8')

    job = job_Q[0]

    job_Q.pop(0)

    print("process strat. slot:", slot, "job_Q len:", len(job_Q), "job:", job)
    # proc = await asyncio.create_subprocess_shell("bash random_job_scripts/" + str(slot) + "_" + job + ".sh",
    #                                        shell=True,
    #                                        executable="/bin/bash",
    #                                        stderr=subprocess.PIPE,
    #                                        encoding='utf-8')

    proc = await asyncio.create_subprocess_shell("bash random_job_scripts/" + str(slot) + "_" + job + ".sh",
                                           shell=True,
                                           executable="/bin/bash",
                                           encoding='utf-8')




    ret_w = await proc.wait()
    print("process end. slot:", slot, "job_Q len:", len(job_Q))
    # print(ret_w)

    if len(job_Q) > 0:
        if slot == 1:
            return await schedule(GPU_Q, 1, job_Q)

        elif slot == 2:
            return await schedule(GPU_Q, 2, job_Q)


async def main():
    global gpu_mem_cap
    gpu_mem_cap = 0
    # await asyncio.gather(
    #     schedule(job_Q, 1, job_Q),
    #     schedule(job_Q, 2, job_Q)
    # )



if __name__ == '__main__':
    num_of_slot = 2
    num_of_job = 10
    job_Q = []
    for _ in range(0, num_of_job):
        job_Q.append(generate_scripts())
    print(job_Q)

    job_Q = ["cifar10_alexnet_sync_batch32", "cifar10_alexnet_sync_batch32", "cifar10_alexnet_sync_batch32",
             "cifar10_alexnet_sync_batch32", "cifar10_alexnet_sync_batch32", "cifar10_alexnet_sync_batch32",
             "cifar10_alexnet_sync_batch32", "cifar10_alexnet_sync_batch32", "cifar10_alexnet_sync_batch32",
             "cifar10_alexnet_sync_batch32"]

    jobs = [schedule(job_Q, slot+1, job_Q) for slot in range(num_of_slot)]
    loop = asyncio.get_event_loop()  # 이벤트 루프를 얻음
    loop.run_until_complete(asyncio.wait(jobs))  # main이 끝날 때까지 기다림
    loop.close()
    print("FINISH")
