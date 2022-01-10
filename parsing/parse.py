HOUR = 3600
MINUTE = 60
WARM_UP = 10
ITERATIONS = 100

def raw_log_to_list(raw_log_path):

    raw_log = open(raw_log_path, 'r').read().split("New Step START\n")

    raw_log_per_iter = []
    for i in range(WARM_UP + 1, WARM_UP + ITERATIONS + 1):
        raw_log_per_iter.append(raw_log[i].split("\n"))

    print(raw_log_per_iter[1])

    raw_log_per_iter_usec = []
    for iter_log in raw_log_per_iter:
        iter_log.remove("")
        iter_log_only_time = [line.split(" ")[1] for line in iter_log]
        iter_log_only_usec = []
        for line in iter_log_only_time:
            time = line.split(".")
            HMS = list(map(int, time[0].split(":")))
            usec = int(time[1].split(":")[0])
            usec = usec + HMS[0] * HOUR * 1000000 + HMS[1] * MINUTE * 1000000 + HMS[2] * 1000000
            iter_log_only_usec.append(usec)
        iter_log_only_usec.sort()
        raw_log_per_iter_usec.append(iter_log_only_usec)

    return raw_log_per_iter_usec


def timestamp_group(timestamp):

    for iter in range(ITERATIONS):
        timediff = []
        for i in range(len(timestamp[iter])-1):
            t = timestamp[iter][i+1] - timestamp[iter][i]
            timediff.append(t)
        # print(len(timestamp[iter]))
        print("길이: ", len(timediff))
        print("max: ", timediff.index(max(timediff)))

        print(timestamp[iter][timediff.index(max(timediff))-5] - timestamp[iter][0])


def total_tx(file):
    log = open(file, 'r').read().split("\n")
    total_tx_bytes = 0
    for line in log:
        if "AllocatedBytes()" in line:
            if "job:worker" not in line:
                bytes = line.split(",")[3]
                # print(bytes)
                total_tx_bytes = total_tx_bytes + int(bytes)
            else:
                print(line)

    print("result: ", total_tx_bytes)


def worker_send(file):
    log = open(file, 'r').read().split("\n")
    tensor_list = []
    for line in log:
        if "AllocatedBytes()" in line:
            if "job:ps/replica:0/task:0/device:CPU" in line:
                tensor = line.split(",")[1]
                tensor_list.append(tensor)

    # print("result: ", tensor_list)
    return tensor_list


def PS_recv(file):
    log = open(file, 'r').read().split("\n")
    new_log = []
    tensor_list = []
    for line in log:
        if "sendrecv_ops.cc" in line:
            new_log.append(line.split(" ")[4])

    for line in new_log:
        split_line = line.split(";")
        if "job:worker/replica:0/task:0" in split_line[0]:
            tensor_list.append(split_line[3])

    # print("result: ", tensor_list)
    return tensor_list


def parse_3timestamp(file):
    raw_log = open(file, 'r').read().split("New Step START\n")

    raw_log_per_iter = []
    for i in range(WARM_UP + 1, WARM_UP + ITERATIONS + 1):
        raw_log_per_iter.append(raw_log[i].split("\n"))

    print(raw_log_per_iter[1])

if __name__ == '__main__':
    # timestamp = raw_log_to_list("core_log.txt")
    # timestamp_group(timestamp)

    # worker_send_tensor_list = worker_send("core_log_w1.txt")
    # PS_recv_tensor_list = PS_recv("core_log_ps1.txt")
    #
    # print(len(worker_send_tensor_list))
    # print(len(PS_recv_tensor_list))
    #
    # s = set(worker_send_tensor_list).difference(set(PS_recv_tensor_list))
    # print(len(s))
    # print(s)
    # s = set(PS_recv_tensor_list).difference(set(worker_send_tensor_list))
    # print(len(s))

    parse_3timestamp("core_log_3timestamp.txt")

