#!/bin/sh

## !!!!!!!!! preparing for the environment setting !!!!!!!!! ##

EVsetting()
{
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
}

# %EVsetting
# Notice if you want to avoid system crashing beacuse of too much variable, you can cancel the "EVsetting" above :D
# progress starting #

chmod +x -R *
chmod -R 750 /home/szk/software/g16
# give all the file relative permissions in the system 

##
## PyMol startup script
## And to get our target protein
##
PymolFunction()
{
	PORT1="1atl"
	# make sure which part of the protein you want to remove
	ion1="resi 403"
	ion2="resi 401"
	# create our own script
	echo "pwd
	fetch $PORT1 
	remove solvent
	remove chain B
	remove $ion1
	remove $ion2
	save complex.pdb
	quit " > script.pml
	/snap/bin/pymol-oss.pymol script.pml
}

PymolFunction

#end

########################################
#                                      #
#  preparing our own protein structure #
#                                      #
########################################

# AmberTools21
grep -v -e "0QI" -e "CONNECT" complex.pdb > protein.pdb
grep "0QI" complex.pdb > 0QI.pdb

# measure the pKa of the residues in the protein
# propka3 protein.pdb
pdb4amber -i protein.pdb -o protein4amber.pdb
# Here also you can call Avodgro to dispose micromolecules
obabel -ipdb 0QI.pdb -opdb -O 0QI.H.pdb -h

########################################
#                                      #
# generate the topology file of ligand #
#                                      #
########################################

obabel 0QI.H.pdb -ipdb -omol2 -O ligand.mol2
ztop.py -g "ligand.mol2;q=am1-bcc;ff=gaff" -o ligand.prmtop,ligand.inpcrd
# convert amber format topology into gromacs format
acpype -p ligand.prmtop -x ligand.inpcrd -d
mv LIG.amb2gmx/LIG_GMX.gro /home/szk/Desktop
mv LIG.amb2gmx/LIG_GMX.top /home/szk/Desktop
# Notice : the mol2 file in the ligand_Amber adapt gaff2 forcefield, so it cannot display normally in gaussview
obabel 0QI.H.pdb -ipdb -oxyz -O ligand.xyz

echo '!!!!!you are in the second bash file to calculate resp charge now!!!!!'

#sed -i '45 i %nproc=8' RESP.sh
#sh RESP.sh ligand.xyz

########################################
#                                      #
# use the resp charge replace am1-bcc  #
#                                      #
########################################

# Notice : it is still need to be added afterwhile

########################################
#   GROMACS PART QMMM PREPARATION      #
########################################

gmx_cp2k editconf -f LIG_GMX.gro -o ligand.pdb
sed -i '$d' ligand.pdb && sed -i '$d' ligand.pdb
cat ligand.pdb protein.pdb >> system.pdb

cp LIG_GMX.top amber99sb-ildn.ff/LIG.rtp
cd amber99sb-ildn.ff
chmod +x *
# change the topology file of our micromolecule


Function()
{
	sed -i '/\[ atoms \]/,/\[ system \]/!d' LIG.rtp && sed -i '$d' LIG.rtp
	sed -i '/\[ pairs \]/,/\[ angles \]/{/\[ pairs \]/!{/\[ angles \]/!d}}' LIG.rtp 
	sed -i 's/\[ pairs \]/ /g' LIG.rtp
	sed -i '1i[ bondedtypes ]' LIG.rtp 
	sed -n '23p' aminoacids.rtp > a.txt && sed -i '1r a.txt' LIG.rtp
	sed -i -e 's/\[ dihedrals \] ; impropers/\[ impropers \]/g' LIG.rtp && sed -i '3i [ LIG ]' LIG.rtp
}

Function

sed -n '6,53p' LIG.rtp > LIG_atoms.txt 
sed -n '57,104p' LIG.rtp > LIG_bonds.txt 
sed -n '109,192p' LIG.rtp > LIG_angles.txt
sed -n '197,331p' LIG.rtp > LIG_dihedrals.txt 
sed -n '336,344p' LIG.rtp > LIG_impropers.txt
sed -i '6,53d' LIG.rtp
sed -i '9,56d' LIG.rtp
sed -i '13,96d' LIG.rtp
sed -i '17,151d' LIG.rtp
sed -i '21,29d' LIG.rtp

awk '{ print $5 "   " $2 "   " $7 "   " $1 }' LIG_atoms.txt > re_atoms.txt && cat re_atoms.txt
awk '{ print $7 "   " $9 "   " $4 "   " $5 }' LIG_bonds.txt > re_bonds.txt && cat re_bonds.txt
awk '{ print $8 "   " $10 "   " $12 "   " $5 "   " $6 }' LIG_angles.txt > re_angles.txt && cat re_angles.txt
awk '{ print $10 "      " $11 "      " $12 "      " $13 "      " $6 "      " $7 "      " $8 }' LIG_dihedrals.txt > re_dihedrals.txt && cat re_dihedrals.txt && sed -e 's/[-]//g' re_dihedrals.txt > rem_dihedrals.txt

rm -rf re_dihedrals.txt

awk '{ print $10 "      " $11 "      " $12 "      " $13 "      " $6 "      " $7 "      " $8 }' LIG_impropers.txt > re_impropers.txt && cat re_impropers.txt && sed -e 's/[-]//g' re_impropers.txt > rem_impropers.txt

rm -rf re_impropers.txt

sed -i '5r re_atoms.txt' LIG.rtp
sed -i '56r re_bonds.txt' LIG.rtp
sed -i '108r re_angles.txt' LIG.rtp
sed -i '196r rem_dihedrals.txt' LIG.rtp
sed -i '335r rem_impropers.txt' LIG.rtp

##########################################
#                                        #
#   gromacs which is with cp2k working   # 
#                                        # 
##########################################
chmod +x *
cd ..
chmod +x *
FunctionOfgromacs()
{
	gmx_cp2k pdb2gmx -f system.pdb -o system.gro -p topol.top 
	gmx_cp2k editconf -f system.gro -o system_box.gro -d 0.6 -bt cubic
	# Notice : you can also set the box length almost at 0.5-1.5
	gmx_cp2k solvate -cp system_box.gro -o system_SOL.gro -p topol.top
	gmx_cp2k grompp -f em.mdp -c system_SOL.gro -p topol.top -o em.tpr -maxwarn 10
	gmx_cp2k genion -s em.tpr -p topol.top -o final.gro -neutral
	gmx_cp2k grompp -f em.mdp -c final.gro -p topol.top -o em.tpr 
	gmx_cp2k mdrun -v -deffnm em
	gmx_cp2k grompp -f pr.mdp -c em.gro -p topol.top -r em.gro -o pr.tpr 
	gmx_cp2k mdrun -v -deffnm pr
	#!!!!!!!!!!!!!!QM REGION SELECTION!!!!!!!!!!!!!!!!!!!#
	gmx_cp2k make_ndx -f pr.gro
	# the step you need to type by yourself
	gmx_cp2k grompp -f md.mdp -c pr.gro -p topol.top -o md.tpr -n index.ndx -maxwarn 10

	mpirun -np 16 gmx_cp2k mdrun -v -deffnm md
}

FunctionOfgromacs

echo "YEAH ! ! ! ! "
