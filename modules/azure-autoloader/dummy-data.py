import faker, json, time, tempfile, shutil, os, pathlib, sys
fake = faker.Faker()

checkin_schema = 'ts timestamp, name string, date date, job string, geo array<double>, metric int'

def fake_record():
  lat, long = fake.location_on_land(True)
  return {'ts': int(time.time()),
          'name': fake.first_name(),
          'date': str(fake.date_between(start_date='-14d', end_date='today')),
          'job': fake.job(),
          'geo': [float(lat), float(long)],
          'metric': fake.random_int(1,100)}

def generate_checkins(amount=2, source='checkins'):
  for _ in range(0, amount+1):
    record = fake_record()
    y, m, d = record['date'].split('-')
    metric = record['metric']
    ts = record['ts']
    mount = pathlib.Path('/dbfs/mnt/autoloader')
    # let's simulate very difficult case of partitioning
    folder = mount / source / f'year={y}' / f'month={m}' / f'day={d}'
    folder.mkdir(parents=True, exist_ok=True)
    with open(f'{folder}/fake-{ts}.json', 'w') as f:
      json.dump(record, f)

def fake_file(temp_dir):
  file_records = fake.random_int(500,1000)
  file_date = str(fake.date_between(start_date='-14d', end_date='today'))
  ts = int(time.time())
  temp_file = f'{temp_dir}/fake-{ts}.json'
  with open(temp_file, 'w') as f:
    for _ in range(0, file_records+1):
      record = fake_record()
      record['date'] = file_date
      json.dump(record, f)
      f.write("\n")
  print(f'Written {file_records} records to {temp_file}')
  return temp_file, file_date

def increment_folder(mounted_folder, files=10):
  temp_dir = tempfile.mkdtemp()
  mount = pathlib.Path(f'/dbfs/mnt/{mounted_folder}')
  for x in range(0, files+1):
    temp_file, date = fake_file(temp_dir)
    y, m, d = date.split('-')
    folder = mount / f'year={y}' / f'month={m}' / f'day={d}'
    folder.mkdir(parents=True, exist_ok=True)
    shutil.move(temp_file, folder / os.path.basename(temp_file))
    print(f'Moved {temp_file} to {folder}')

def prepare_local(local_folder, files=100):
  temp_dir = tempfile.mkdtemp()
  mount = pathlib.Path(local_folder)
  for x in range(0, files+1):
    temp_file, date = fake_file(temp_dir)
    y, m, d = date.split('-')
    folder = mount / f'year={y}' / f'month={m}' / f'day={d}'
    folder.mkdir(parents=True, exist_ok=True)
    os.rename(temp_file, folder / os.path.basename(temp_file))
    print(f'Moved {temp_file} to {folder}')

def prepare_local_not_partitioned(local_folder, files=100):
  temp_dir = tempfile.mkdtemp()
  mount = pathlib.Path(local_folder)
  for x in range(0, files+1):
    temp_file, date = fake_file(temp_dir)
    y, m, d = date.split('-')
    folder = mount / y / m / d
    folder.mkdir(parents=True, exist_ok=True)
    os.rename(temp_file, folder / os.path.basename(temp_file))
    print(f'Moved {temp_file} to {folder}')


if __name__ == '__main__':
  if len(sys.argv) < 2:
    print('Need name of the folder')
    sys.exit(1)
  if 'not_partitioned' in sys.argv:
    prepare_local_not_partitioned(sys.argv[1])
    sys.exit(0)
  prepare_local(sys.argv[1])
