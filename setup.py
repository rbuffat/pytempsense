'''
Created on Mar 11, 2018

@author: rene
'''


from setuptools import setup, find_packages
from Cython.Build import cythonize
from setuptools.extension import Extension

setup(
    name='pytempsense',
    version="0.1.dev",
    packages=find_packages(),
    ext_modules=cythonize([Extension('pytempsense.bme280api', ['pytempsense/bme280driver/bme280.c',
                                                            'pytempsense/bme280driver/bme280_helper.c',
                                                            'pytempsense/bme280api.pyx'])])
)
