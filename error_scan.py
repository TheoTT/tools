import os
import json
import pymysql

from datetime import datetime


class ErrorScaner:
    init_error_num = None
    current_error_num = None

    def __init__(self, logfile):
        self.init_error_num = self._load_init_error_num()
        self.current_error_num = self._scan_logfile_error(logfile)

    def _load_init_error_num(self):
        result = {
            "error_num": None
        }

        if os.path.exists('result.json'):
            with open('result.json', 'r') as f:
                result = json.load(f)
        else:
            with open('result.json', 'w') as f:
                json.dump(result, f)

        return result["error_num"]

    def _scan_logfile_error(self, logfile):
        try:
            with open(logfile, 'rb') as f:
                lines = f.readlines()
                error_lines = [line.decode(encoding='GBK') for line in lines if line.decode(encoding='GBK').startswith('[error]')]
                # print(error_lines, len(error_lines))
                return len(error_lines)
        except FileNotFoundError:
            print(f'logfile: {logfile} is not exists!')
            return None

    def update_result(self, conn, init):
        # update init_json
        result = {
            "error_num": self.current_error_num
        }
        with open('result.json', 'w') as f:
            json.dump(result, f)

        # update to mysql
        if not init:
            try:
                with conn.cursor() as cursor:
                    # Create a new record
                    sql = "INSERT INTO `error_record` (`host`, `created_time`) VALUES (%s, %s)"
                    cursor.execute(sql, ('127.0.0.1', datetime.now()))

                    # connection is not autocommit by default. So you must commit to save
                    # your changes.
                    conn.commit()
            finally:
                conn.close()


if __name__ == '__main__':
    conn = pymysql.connect(host='127.0.0.1', user='root', port=6606,
                           password='grapeadmin', db='errorscanerdb',
                           charset='utf8mb4',
                           cursorclass=pymysql.cursors.DictCursor)

    es = ErrorScaner('log.sender')
    print(es.init_error_num, es.current_error_num)
    if es.init_error_num is None:
        es.update_result(conn, init=True)
    elif es.init_error_num < es.current_error_num:
        es.update_result(conn, init=False)
