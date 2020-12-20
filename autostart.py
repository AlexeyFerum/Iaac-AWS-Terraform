import argparse
from time import sleep
from croniter import croniter
from datetime import datetime
from subprocess import Popen
from multiprocessing import Process

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Simple loop autostarter.')
    parser.add_argument('-c', '--crontab', default='00 00 */1 * *', dest='crontab',
                        help='Schedule of initialization in Crontab format', type=str)
    parser.add_argument('-f', '--file', dest='file',
                        help='File args and destination path',
                        type=str, required=True)

    args = parser.parse_args()
    launch_list = str(args.file).split(' ')

    while True:
        print(f'\n\n', datetime.now(), ': App initialization\n')

        Popen(launch_list)
        sleep(1)

        base = datetime.now()
        nearest = croniter(args.crontab, base).get_next(datetime)
        print(f'Next init in ', nearest)

        sleep((nearest-base).seconds)