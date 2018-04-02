from setuptools import setup, find_packages
from Cython.Build import cythonize
from setuptools.extension import Extension
import sys

with open('pytempsense/__init__.py', 'r') as f:
    for line in f:
        if line.find("__version__") >= 0:
            version = line.split("=")[1].strip()
            version = version.strip('"')
            version = version.strip("'")
            break


ext_modules=cythonize([Extension('pytempsense.bme280api', ['pytempsense/bme280driver/bme280.c',
                                                           'pytempsense/bme280driver/bme280_helper.c',
                                                           'pytempsense/bme280api.pyx'])])


open_kwds = {}
if sys.version_info > (3,):
    open_kwds['encoding'] = 'utf-8'

with open('VERSION.txt', 'w', **open_kwds) as f:
    f.write(version)

with open('README.md', **open_kwds) as f:
    readme = f.read()

setup_args = dict(
    metadata_version='1.2',
    name='pytempsense',
    version=version,
    requires_python='>=2.7',
    requires_external='GDAL (>=1.8)',
    description="pytempsense allows to access BME280 sensors over I2C on Raspberry Pi's",
    license='MIT',
    keywords='BME280 raspberry pi',
    author='Rene Buffat',
    author_email='buffat@gmail.com',
    maintainer='Rene Buffat',
    maintainer_email='buffat@gmail.com',
    url='https://github.com/rbuffat/pytempsense',
    long_description=readme + "\n",
    package_dir={'': '.'},
    packages=['pytempsense'],
    ext_modules=ext_modules,
    classifiers=[
        'Development Status :: 3 - Alpha',
        'Intended Audience :: Developers',
        'Intended Audience :: Education',
        'License :: OSI Approved :: MIT License',
        'Operating System :: POSIX :: Linux',
        'Programming Language :: Python :: 2',
        'Programming Language :: Python :: 3'])


setup(**setup_args)

