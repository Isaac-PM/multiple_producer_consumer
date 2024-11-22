from os import remove
from os.path import exists
from typing import Callable
import sys
import random
import csv
import time

seconds_to_sleep: int = 1


def main(input_id: str, element_count: int, runs_to_execute: int) -> None:
    input_lock_file_name: str = f"input_{input_id}.lock"
    input_file_name: str = f"input_{input_id}.csv"

    input_is_ready: Callable[[], bool] = lambda: exists(input_lock_file_name)
    signal_input_is_ready: Callable[[], None] = lambda: open(
        input_lock_file_name, "w"
    ).close()

    output_lock_file_name: str = f"output_{input_id}.lock"
    output_file_name: str = f"output_{input_id}.csv"

    output_is_ready: Callable[[], bool] = lambda: exists(output_lock_file_name)
    signal_output_processed: Callable[[], None] = lambda: remove(output_lock_file_name)

    for i in range(runs_to_execute):
        print(f"Run {i + 1} of {runs_to_execute}")
        if not input_is_ready():
            save_input_file(input_file_name, element_count)
            signal_input_is_ready()
            print(f"Input file {input_file_name} is ready")
            while not output_is_ready():
                time.sleep(seconds_to_sleep)
            load_and_print_output_file(output_file_name)
            signal_output_processed()
        time.sleep(seconds_to_sleep)


def save_input_file(file_name: str, element_count: int) -> None:
    input_file: any = open(file_name, "w")
    input_data: list[str] = []
    for _ in range(element_count):
        input_data.append(str(random.uniform(0, element_count)))
    input_file.write(",".join(input_data))
    input_file.close()


def load_and_print_output_file(file_name: str) -> None:
    print(f"Loading output file {file_name}")
    with open(file_name, newline="") as output_file:
        reader = csv.reader(output_file, delimiter=",", quotechar="|")
        data = next(reader)
        print(data)


EXPECTED_ARGC: int = (
    4  # <input_id> <element_count> <runs_to_execute> <seconds_to_sleep>
)

if __name__ == "__main__":
    argc: int = len(sys.argv)
    if argc != EXPECTED_ARGC + 1:
        print(
            f"Usage: {sys.argv[0]} <input_id> <element_count> <runs_to_execute> <seconds_to_sleep>"
        )
        sys.exit(1)
    seconds_to_sleep = int(sys.argv[4])
    main(sys.argv[1], int(sys.argv[2]), int(sys.argv[3]))
