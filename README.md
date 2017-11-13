# MeterData

## Setup

  - Check out source code from Git
  - Create virtualenv for the project
```
        virtualenv <path to project:i.e C:\MeterData>
```
  - Activate virtualenv of the project
```
        <path to project:i.e C:\MeterData>\Scripts\activate
```
  - Instal dependencies
```
        cd <path to project:i.e C:\MeterData>
        pip install -r requirements.txt
```
  - Instal ceODBC
```
        download the ceODBC-2.0.1-cp27-cp27m-win_amd64.whl file from https://www.lfd.uci.edu/~gohlke/pythonlibs/
        pip install ceODBC-2.0.1-cp27-cp27m-win_amd64.whl
```
## SavvyDataLoader

### Build
  - Activate virtualenv of the project
```
        <path to project:i.e C:\MeterData>\Scripts\activate
```
  - Run build script
```
        pyinstaller -F -p C:\MeterData\Lib -p C:\MeterData\Lib\site-packages C:\MeterData\MeterDataLoader.py    
```
### Deploy
 - Copy `SavvyDataLoader.exe` from  <path to project:i.e C:\MeterData>\dist and `MeterDataLoader.cfg` and `logging_config.json` from <path to project:i.e C:\MeterData> to deployment folder