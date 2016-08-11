from distutils.core import setup
import py2exe

setup(
        windows=[{'script': 'ITLK_Dev1_win.py'}],
        options={
                "py2exe":{
                        "unbuffered": True,
                        "optimize": 2,
                        "compressed":True,
                        "dll_excludes": ["MSVCP90.dll"],
                        # "bundle_files": 2
                }
        }
)
