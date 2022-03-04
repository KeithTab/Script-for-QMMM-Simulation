# Script-for-QMMM-Simulation
# Introduction:

Create a bridge between gromacs and cp2k for QMMM simulation is my main purpose all the time and this script QM.sh can realize QMMMM Simulation topology file creation from our initial protein Structure, which as follows are some tips when you run this QM script:

# 1.The topology file of the micromolecule 
when you have already generate the .rtp file of the organic molecule, you'd better modify the file residuetypes.dat which is in your gromacs path /share/gromacs/top,and on the other hand, we also need to add our micromolecule's atomtypes which was produced by the ztop.py (reference link: http://bbs.keinsci.com/thread-22171-1-1.html) script to the atomtypes.atp in our own forcefields.

# 2.The RESP charge modification
Our script includes the RESP.h and you can call this script in anytime, so in order to achieve this target, you'd better set these environment variables just below:

        export PATH=$PATH:/home/szk/software/coordmagic
        export KMP_STACKSIZE=200M
        ulimit -s unlimited
        export Multiwfnpath=/home/szk/software/Multiwfn
        export PATH=$PATH:/home/szk/software/Multiwfn
        export PATH=$PATH:/usr/local/plumed/bin
        export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/plumed/lib
        export PATH=$PATH:/home/szk/software/cp2k/exe/local
        export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/home/szk/software/cp2k/lib/local/pdbg
        export PATH=$PATH:/usr/local/gromacs/bin
        export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/gromacs/lib
        export g16root=/home/szk/software
        export GAUSS_SCRDIR=/home/szk/software/g16/scratch
        source /home/szk/software/g16/bsd/g16.profile
        export AMBERHOME=/home/szk/Downloads/amber20_src
        export PATH=$PATH:$AMBERHOME/bin
        export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$AMBERHOME/lib
        source /home/szk/software/amber20/amber.sh
        
and your home path can be replaced by your own path, that's a easy operation :D
reference link: (http://sobereva.com/multiwfn/)
# 3.Some existing problems
Still need to modify some little bugs when combining the pdb file of micromolecule and protein, because of the different atom type such as "O1", Secondly, some path settings are still needed to be improved later.


