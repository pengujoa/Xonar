import parsing.parse_corelog as PC
import os
import argparse
import csv


def main(args):
    is_worker = True
    log_dir = args.log_dir + args.DDL_env + "/"
    pbtxt_dir = args.pbtxt_dir + args.DDL_env + "/"
    time_dir = args.time_dir + args.DDL_env + "/"

    model_list = model_list_from_pbtxt_dir(pbtxt_dir)

    save = [["Model", "w_idx", "RX_time(ms)", "TX_time(ms)", "GPU_Active(ms)", "GPU_Idle(ms)", "1_Iter_time(ms)", "Total_time(ms)"]]

    count = 0

    for DDL_model in model_list:
        result = PC.parse_corelog(DDL_model, log_dir, pbtxt_dir, time_dir, args.num_ps, args.num_worker, is_worker)
        for w_idx in range(args.num_worker):
            save.append(result[w_idx])
        count = count + 1
        if count == 10:
            break

    csvfile = open(args.save_dir + args.save_file, "w", newline="")
    csvwriter = csv.writer(csvfile)

    for row in save:
        csvwriter.writerow(row)

    csvfile.close()




def model_list_from_pbtxt_dir(pbtxt_dir):
    model_list = os.listdir(pbtxt_dir)
    return model_list


def get_arguments():
    parser = argparse.ArgumentParser()
    parser.add_argument('--num_worker', type=int, default=2, help='an integer for printing repeatably')
    parser.add_argument('--num_ps', type=int, default=2, help='an integer for printing repeatably')
    parser.add_argument('--DDL_env', type=str, help='an string for printing repeatably')
    parser.add_argument('--log_dir', type=str, help='an string for printing repeatably')
    parser.add_argument('--pbtxt_dir', type=str, help='an string for printing repeatably')
    parser.add_argument('--time_dir', type=str, help='an string for printing repeatably')
    parser.add_argument('--save_dir', type=str, default="", help='an string for printing repeatably')
    parser.add_argument('--save_file', type=str, default="save.csv", help='an string for printing repeatably')

    args = parser.parse_args()

    return args


if __name__ == '__main__':
    args = get_arguments()
    main(args)

