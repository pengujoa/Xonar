import os
import subprocess
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


def schedule(GPU_Q, slot, job_Q, first):


    proc = subprocess.Popen("bash random_job_scripts/" + str(slot) + "_" + job_Q[0] + ".sh", shell=True,
                        executable="/bin/bash",
                        stderr=subprocess.PIPE,
                        encoding='utf-8')

    job_Q.pop(0)

    ret = proc.communicate()

    if first:
        schedule(GPU_Q, 2, job_Q, False)

    ret_w = proc.wait()
    print("process end. slot:", slot, "job_Q len:", len(job_Q))
    print(ret_w)



    if len(job_Q) > 0:
        if slot == 1:
            schedule(GPU_Q, 2, job_Q, False)
            return ret_w
        elif slot == 2:
            schedule(GPU_Q, 1, job_Q, False)
            return ret_w

    # while len(job_Q) == 0:
    #     os.system("bash random_job_scripts/" + job_Q[0])
    #     job_Q.pop(0)
    return ret_w







if __name__ == '__main__':
    num_of_job = 10
    job_Q = []

    for _ in range(0, 10):
        job_Q.append(generate_scripts())

    print(job_Q)

    schedule(job_Q, 1, job_Q, True)

