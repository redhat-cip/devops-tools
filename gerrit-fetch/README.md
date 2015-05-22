# make-mrconfig

Make mrconfig is a script for generate a `.mrconfig` file for `mr` and
clone/fetch all project of a namespace (for this example, all stackforge puppet
modules)

```shell
apt-get install mr # or myrepos
mkdir stackforge
./make-mrconfig
echo $(pwd)/.mrconfig >> ~/.mrtrust
mr -j 10 update
```
