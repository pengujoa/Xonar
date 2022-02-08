from parse import compile
import os

parseformat = "{hour}:{minute}:{second}:{millisecond}  Device {devicenum}: {devicename}  GPU Util: {GPUUtil}  Mem Util: {MemUtil} Mem Usage: {MemUsage}"
foldername = "nvml"
savefoldername = "graph"
logext = ".txt"
outext = ".png"
devicecount = 3

dir = os.path.dirname(os.path.realpath(__file__))
inputdir = os.path.join(dir, foldername)

def getmillisecond(hour, minute, second, millisecond):
    return (int(hour) * 60 * 60 + int(minute) * 60 + int(second)) * 1000 + int(millisecond) 

def getextention(filename):
    return os.path.splitext(filename)[1]

def drawgraphfromdatas(datas,outfilename,graphname="Mem Usage"):
    global devicecount

    # Make the graph
    import matplotlib.pyplot as plt
    import numpy as np

    # Get the data
    #data = np.array(parsed)
    #print(type(parsed[0]))
    #print(type(1))

    # Get the time
    # time = data[]["MemUsage"]

    for dc in range(devicecount):
        parsed = datas[dc]
        starttime = getmillisecond(parsed[0]["hour"], parsed[0]["minute"], parsed[0]["second"], parsed[0]["millisecond"])
        starthour = int(parsed[0]["hour"])

        Time = []
        for i in range(len(parsed)):
            hour = parsed[i]["hour"]
            minute = parsed[i]["minute"]
            second = parsed[i]["second"]
            millisecond = parsed[i]["millisecond"]

            deltatime = getmillisecond(hour, minute, second, millisecond) - starttime
            if deltatime < 0 and int(hour) == 0 and starthour == 23:
                deltatime += 24 * 60 * 60 * 1000
            Time.append(deltatime)



        # Get the GPU Util
        GPUUtil = [int(parsed[i]["GPUUtil"]) for i in range(len(parsed))]
        # print(gpuutil)
        # Get the Mem Util
        MemUtil = [int(parsed[i]["MemUtil"]) for i in range(len(parsed))]
        # Get the Mem Usage
        MemUsage = [int(parsed[i]["MemUsage"]) for i in range(len(parsed))]
        plt.plot(Time,MemUsage, label="Mem Usage" + str(dc))

    plt.legend()
    plt.xlabel("Time (ms)")
    plt.ylabel("Mem Usage (MB)")
    plt.title(graphname)
    plt.savefig(outfilename)
    plt.close()
    #plt.show()

def makegraph(filename):
    global inputdir
    global logext
    global parseformat
    global foldername
    global savefoldername
    global outext

    # Get the full path
    path = os.path.join(inputdir, filename)

    dataname = os.path.splitext(filename)[0]
    savefilename = dataname + outext 
    savepath = os.path.join(dir, savefoldername, savefilename)

    p = compile(parseformat)
    parsed = [[] for i in range(devicecount)]
    # Open the file
    with open(path, 'r') as f:
        # Read the file
        lines = f.readlines()
        # Parse the lines
        for line in lines:
            d = p.parse(line)
            if d:
                devicenum = int(d.named["devicenum"])
                parsed[devicenum].append(d.named)
                # print(d.named)

    drawgraphfromdatas(parsed,savepath,dataname)

if __name__ == "__main__":
    files = os.listdir(inputdir)

    for file in files:
        if getextention(file) == logext:
            makegraph(file)
    # print(inputdir)