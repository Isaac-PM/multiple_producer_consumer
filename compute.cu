#include <iostream>
#include <fstream>
#include <sstream>
#include <unistd.h>
#include <string>

#define THREADS_PER_BLOCK 16
uint secondsToSleep = 1;

__global__ void arrayDifference(const float *a, const float *b, float *results, size_t elementCount)
{
    size_t i = blockDim.x * blockIdx.x + threadIdx.x;
    if (i < elementCount)
    {
        results[i] = a[i] - b[i];
    }
}

__host__ void executeKernel(float *a, float *b, float *results, size_t elementCount)
{
    dim3 dimGrid((elementCount + THREADS_PER_BLOCK - 1) / THREADS_PER_BLOCK, 1, 1);
    dim3 dimBlock(THREADS_PER_BLOCK, 1, 1);
    arrayDifference<<<dimGrid, dimBlock>>>(a, b, results, elementCount);
    cudaDeviceSynchronize();
    std::cout << "Input files loaded and processed, results:\n";
    for (size_t i = 0; i < elementCount; i++)
    {
        std::cout << results[i] << (i == elementCount - 1 ? "\n" : ",");
    }
}

__host__ void loadInputFile(float *a, float *b, size_t elementCount)
{
    bool inputIsReady = false;
    while (!inputIsReady)
    {
        std::ifstream lockA("./input_a.lock");
        std::ifstream lockB("./input_b.lock");
        inputIsReady = lockA.is_open() && lockB.is_open();
        std::cout << "Waiting for input files...\n";
        sleep(secondsToSleep);
    }
    std::cout << "Loading data...\n";

    std::cout << "Removing output files...\n";
    std::remove("./output_a.csv");
    std::remove("./output_a.lock");
    std::remove("./output_b.csv");
    std::remove("./output_b.lock");

    std::string lineA;
    std::string lineB;

    std::cout << "Parsing input files...\n";
    std::ifstream inputA("./input_a.csv");
    std::ifstream inputB("./input_b.csv");

    auto parseLine = [](float *data, std::string line)
    {
        size_t i = 0;
        std::string token;
        std::istringstream tokenStream(line);
        while (std::getline(tokenStream, token, ','))
        {
            data[i++] = std::stof(token);
        }
    };

    if (inputA.is_open() && inputB.is_open())
    {
        getline(inputA, lineA);
        parseLine(a, lineA);
        inputA.close();
        getline(inputB, lineB);
        parseLine(b, lineB);
        inputB.close();
    }
}

__host__ void saveOutputFile(float *results, size_t elementCount)
{
    std::cout << "Saving data...\n";
    std::ofstream outputA("./output_a.csv");
    std::ofstream outputB("./output_b.csv");

    for (size_t i = 0; i < elementCount; i++)
    {
        outputA << results[i] << (i == elementCount - 1 ? "" : ",");
        outputB << (0 - results[i]) << (i == elementCount - 1 ? "" : ",");
    }
    outputA << '\n';
    outputB << '\n';

    outputA.close();
    outputB.close();
}

#define EXPECTED_ARGC 3 // <element_count> <runs_to_execute> <seconds_to_sleep>

int main(int argc, char *argv[])
{
    if (argc != EXPECTED_ARGC + 1)
    {
        std::cout << "Usage: <element_count> <runs_to_execute> <seconds_to_sleep>\n";
        return EXIT_FAILURE;
    }

    size_t elementCount = std::stoul(argv[1]);
    size_t runsToExecute = std::stoul(argv[2]);
    secondsToSleep = std::stoul(argv[3]);

    float *a, *b, *results;
    cudaMallocManaged(&a, elementCount * sizeof(float));
    cudaMallocManaged(&b, elementCount * sizeof(float));
    cudaMallocManaged(&results, elementCount * sizeof(float));

    for (size_t i = 0; i < runsToExecute; i++)
    {
        std::cout << "Run " << i + 1 << " of " << runsToExecute << '\n';

        loadInputFile(a, b, elementCount);
        executeKernel(a, b, results, elementCount);
        saveOutputFile(results, elementCount);

        remove("./input_a.lock");
        remove("./input_b.lock");

        auto signalOutputProcessed = [](const char *filename)
        {
            std::fstream lock;
            lock.open(filename, std::ios::out);
            lock.is_open();
            lock.close();
        };

        signalOutputProcessed("./output_a.lock");
        signalOutputProcessed("./output_b.lock");
    }

    cudaFree(a);
    cudaFree(b);
    cudaFree(results);
    cudaDeviceReset();

    std::cout << "Done!\n";

    return EXIT_SUCCESS;
}