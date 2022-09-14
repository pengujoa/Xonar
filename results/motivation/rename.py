import sys
from os import rename, listdir

def file_rename(file_path):
    for num in range(9,23):
        number = num
        new_number = num + 28
        single_fifo_log = "log_single_fifo_" + str(number) + ".txt"
        single_fifo_gpu = "gpu_single_fifo_" + str(number) + ".txt"
        concur_fifo_log = "log_concur_fifo_" + str(number) + ".txt"
        concur_fifo_gpu = "gpu_concur_fifo_" + str(number) + ".txt"
        xonar_fifo_log = "log_concur_xonar_" + str(number) + ".txt"
        xoanr_fifo_gpu = "gpu_concur_xonar_" + str(number) + ".txt"
        new_single_fifo_log = "log_single_fifo_" + str(new_number) + ".txt"
        new_single_fifo_gpu = "gpu_single_fifo_" + str(new_number) + ".txt"
        new_concur_fifo_log = "log_concur_fifo_" + str(new_number) + ".txt"
        new_concur_fifo_gpu = "gpu_concur_fifo_" + str(new_number) + ".txt"
        new_xonar_fifo_log = "log_concur_xonar_" + str(new_number) + ".txt"
        new_xoanr_fifo_gpu = "gpu_concur_xonar_" + str(new_number) + ".txt"

        rename(file_path + single_fifo_log, file_path + new_single_fifo_log)
        rename(file_path + single_fifo_gpu, file_path + new_single_fifo_gpu)
        rename(file_path + concur_fifo_log, file_path + new_concur_fifo_log)
        rename(file_path + concur_fifo_gpu, file_path + new_concur_fifo_gpu)
        rename(file_path + xonar_fifo_log, file_path + new_xonar_fifo_log)
        rename(file_path + xoanr_fifo_gpu, file_path + new_xoanr_fifo_gpu)

    return


if __name__ == '__main__':
    file_rename("D:/2021/개인연구/Xonar/git/results/motivation/final/d/")