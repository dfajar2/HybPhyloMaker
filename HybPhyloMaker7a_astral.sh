#!/bin/bash
#----------------MetaCentrum----------------
#PBS -l walltime=2h
#PBS -l nodes=1:ppn=4
#PBS -j oe
#PBS -l mem=16gb
#PBS -l scratch=2gb
#PBS -N HybPhyloMaker7a_Astral
#PBS -m abe

#-------------------HYDRA-------------------
#$ -S /bin/bash
#$ -pe mthread 2
#$ -q sThM.q
#$ -l mres=8G,h_data=8G,h_vmem=8G,himem
#$ -cwd
#$ -j y
#$ -N HybPhyloMaker7a_Astral
#$ -o HybPhyloMaker7a_Astral.log

# ********************************************************************************
# *    HybPhyloMaker - Pipeline for Hyb-Seq data processing and tree building    *
# *                       Script 07a - Astral species tree                       *
# *                                   v.1.1.3                                    *
# * Tomas Fer, Dept. of Botany, Charles University, Prague, Czech Republic, 2016 *
# * tomas.fer@natur.cuni.cz                                                      *
# ********************************************************************************


#Compute species tree using Astral methods from trees saved in single gene tree file (with *.newick suffix)
#Take trees from 72trees${MISSINGPERCENT}_${SPECIESPRESENCE}/${tree}/species_trees/trees${MISSINGPERCENT}_${SPECIESPRESENCE}_rooted_withoutBS.newick
#Run first
#(1) HybPhyloMaker4_missingdataremoval.sh with the same ${MISSINGPERCENT} and ${SPECIESPRESENCE} values
#(2) HybPhyloMaker5a_RAxML_for_selected.sh or HybPhyloMaker5b_FastTree_for_selected.sh with the same ${MISSINGPERCENT} and ${SPECIESPRESENCE} values
#(3) HybPhyloMaker6_roottrees.sh with the same ${MISSINGPERCENT} and ${SPECIESPRESENCE} values

#Complete path and set configuration for selected location
if [[ $PBS_O_HOST == *".cz" ]]; then
	echo -e "\nHybPhyloMaker7a is running on MetaCentrum...\n"
	#settings for MetaCentrum
	#Move to scratch
	cd $SCRATCHDIR
	#Copy file with settings from home and set variables from settings.cfg
	cp $PBS_O_WORKDIR/settings.cfg .
	. settings.cfg
	. /packages/run/modules-2.0/init/bash
	path=/storage/$server/home/$LOGNAME/$data
	source=/storage/$server/home/$LOGNAME/HybSeqSource
	#Add necessary modules
	module add jdk-1.6.0
elif [[ $HOSTNAME == compute-*-*.local ]]; then
	echo -e "\nHybPhyloMaker7a is running on Hydra...\n"
	#settings for Hydra
	#set variables from settings.cfg
	. settings.cfg
	path=../$data
	source=../HybSeqSource
	#Make and enter work directory
	mkdir workdir07a
	cd workdir07a
	#Add necessary modules
	module load java/1.7
else
	echo -e "\nHybPhyloMaker7a is running locally...\n"
	#settings for local run
	#set variables from settings.cfg
	. settings.cfg
	path=../$data
	source=../HybSeqSource
	#Make and enter work directory
	mkdir workdir07a
	cd workdir07a
fi

#Settings for (un)corrected reading frame
if [[ $corrected =~ "yes" ]]; then
	alnpath=80concatenated_exon_alignments_corrected
	alnpathselected=81selected_corrected
	treepath=82trees_corrected
else
	alnpath=70concatenated_exon_alignments
	alnpathselected=71selected
	treepath=72trees
fi
#Setting for the case when working with cpDNA
if [[ $cp =~ "yes" ]]; then
	type="_cp"
else
	type=""
fi

#Add necessary programs and files
cp $source/$astraljar .
cp -r $source/lib .

#Copy genetree file
if [[ $update =~ "yes" ]]; then
	cp $path/${treepath}${type}${MISSINGPERCENT}_${SPECIESPRESENCE}/${tree}/update/species_trees/trees${MISSINGPERCENT}_${SPECIESPRESENCE}_rooted_withoutBS.newick .
else
	cp $path/${treepath}${type}${MISSINGPERCENT}_${SPECIESPRESENCE}/${tree}/species_trees/trees${MISSINGPERCENT}_${SPECIESPRESENCE}_rooted_withoutBS.newick .
fi

#Modify labels in gene tree
sed -i.bak 's/XX/-/g' trees${MISSINGPERCENT}_${SPECIESPRESENCE}_rooted_withoutBS.newick
sed -i.bak 's/YY/_/g' trees${MISSINGPERCENT}_${SPECIESPRESENCE}_rooted_withoutBS.newick

#Copy bootrapped gene tree files (if tree=RAxML or tree=FastTree and FastTreeBoot=yes)
if [[ $mlbs =~ "yes" ]]; then
	if [[ $tree =~ "RAxML" ]]; then
		#Make dir for for bootstraped trees
		mkdir boot
		#Copy RAxML bootstraped trees
		if [[ $update =~ "yes" ]]; then
			cp $path/${alnpathselected}${type}${MISSINGPERCENT}/updatedSelectedGenes/selected_genes_${MISSINGPERCENT}_${SPECIESPRESENCE}_update.txt .
			for i in $(cat selected_genes_${MISSINGPERCENT}_${SPECIESPRESENCE}_update.txt); do
				cp $path/${treepath}${type}${MISSINGPERCENT}_${SPECIESPRESENCE}/RAxML/RAxML_bootstrap*ssembly_${i}.result boot/
			done
		else
			cp $path/${treepath}${type}${MISSINGPERCENT}_${SPECIESPRESENCE}/RAxML/RAxML_bootstrap* boot/
		fi
		#Make a list of bootstraped trees
		ls boot/*bootstrap* > bs-files
	elif [[ $tree =~ "FastTree" && $FastTreeBoot =~ "yes" ]]; then
		#Make dir for for bootstraped trees
		mkdir boot
		#Copy FastTree bootstraped trees
		if [[ $update =~ "yes" ]]; then
			cp $path/${alnpathselected}${type}${MISSINGPERCENT}/updatedSelectedGenes/selected_genes_${MISSINGPERCENT}_${SPECIESPRESENCE}_update.txt .
			for i in $(cat selected_genes_${MISSINGPERCENT}_${SPECIESPRESENCE}_update.txt); do
				cp $path/${treepath}${type}${MISSINGPERCENT}_${SPECIESPRESENCE}/FastTree/*ssembly_${i}_*.boot.fast.trees boot/
			done
		else
			cp $path/${treepath}${type}${MISSINGPERCENT}_${SPECIESPRESENCE}/FastTree/*.boot.fast.trees boot/
		fi
		#Make a list of bootstraped trees
		ls boot/*.boot.fast.trees > bs-files
	fi
fi
#Make dir for results
if [[ $update =~ "yes" ]]; then
	mkdir $path/${treepath}${type}${MISSINGPERCENT}_${SPECIESPRESENCE}/${tree}/update/species_trees/Astral
else
	mkdir $path/${treepath}${type}${MISSINGPERCENT}_${SPECIESPRESENCE}/${tree}/species_trees/Astral
fi

#Run ASTRAL
echo -e "Computing Astral tree..."
if [[ $location == "1" ]]; then
	java -jar $astraljar -i trees${MISSINGPERCENT}_${SPECIESPRESENCE}_rooted_withoutBS.newick -o Astral_${MISSINGPERCENT}_${SPECIESPRESENCE}.tre 2> Astral.log
elif [[ $location == "2" ]]; then
	java -d64 -server -XX:MaxHeapSize=7g -jar $astraljar -i trees${MISSINGPERCENT}_${SPECIESPRESENCE}_rooted_withoutBS.newick -o Astral_${MISSINGPERCENT}_${SPECIESPRESENCE}.tre 2> Astral.log
else
	java -jar $astraljar -i trees${MISSINGPERCENT}_${SPECIESPRESENCE}_rooted_withoutBS.newick -o Astral_${MISSINGPERCENT}_${SPECIESPRESENCE}.tre 2> Astral.log
fi

#(Re)root a final Astral species tree with $OUTGROUP
nw_reroot Astral_${MISSINGPERCENT}_${SPECIESPRESENCE}.tre $OUTGROUP > tmp && mv tmp Astral_${MISSINGPERCENT}_${SPECIESPRESENCE}.tre
#Modify labels in Astral trees
sed -i.bak2 's/-/ /g' Astral*.tre
sed -i.bak2 's/_/ /g' Astral*.tre

#Copy species tree and log to home
if [[ $update =~ "yes" ]]; then
	cp Astral_${MISSINGPERCENT}_${SPECIESPRESENCE}.tre $path/${treepath}${type}${MISSINGPERCENT}_${SPECIESPRESENCE}/${tree}/update/species_trees/Astral
	cp Astral.log $path/${treepath}${type}${MISSINGPERCENT}_${SPECIESPRESENCE}/${tree}/update/species_trees/Astral
else
	cp Astral_${MISSINGPERCENT}_${SPECIESPRESENCE}.tre $path/${treepath}${type}${MISSINGPERCENT}_${SPECIESPRESENCE}/${tree}/species_trees/Astral
	cp Astral.log $path/${treepath}${type}${MISSINGPERCENT}_${SPECIESPRESENCE}/${tree}/species_trees/Astral
fi

if [[ $tree =~ "RAxML" ]] || [[ $tree =~ "FastTree" && $FastTreeBoot =~ "yes" ]]; then
	if [[ $mlbs =~ "yes" ]]; then
		#Run Astral bootstrap
		echo -e "\nComputing Astral multilocus bootrap..."
		if [[ $location == "1" ]]; then
			java -jar $astraljar -i trees${MISSINGPERCENT}_${SPECIESPRESENCE}_rooted_withoutBS.newick -b bs-files -o Astral_${MISSINGPERCENT}_${SPECIESPRESENCE}_allbootstraptrees.tre 2> Astral_boot.log
		elif [[ $location == "2" ]]; then
			java -d64 -server -XX:MaxHeapSize=14g -jar $astraljar -i trees${MISSINGPERCENT}_${SPECIESPRESENCE}_rooted_withoutBS.newick -b bs-files -o Astral_${MISSINGPERCENT}_${SPECIESPRESENCE}_allbootstraptrees.tre 2> Astral_boot.log
		else
			java -jar $astraljar -i trees${MISSINGPERCENT}_${SPECIESPRESENCE}_rooted_withoutBS.newick -b bs-files -o Astral_${MISSINGPERCENT}_${SPECIESPRESENCE}_allbootstraptrees.tre 2> Astral_boot.log
		fi
		#Extract last tree (main species tree based on non-bootstrapped dataset + bootstrap values mapped on it)
		cat Astral_${MISSINGPERCENT}_${SPECIESPRESENCE}_allbootstraptrees.tre | tail -n1 > Astral_${MISSINGPERCENT}_${SPECIESPRESENCE}_withbootstrap.tre
		#(Re)root a final Astral species tree with $OUTGROUP
		nw_reroot Astral_${MISSINGPERCENT}_${SPECIESPRESENCE}_withbootstrap.tre $OUTGROUP > tmp && mv tmp Astral_${MISSINGPERCENT}_${SPECIESPRESENCE}_withbootstrap.tre
		#Modify labels in Astral trees
		sed -i.bak3 's/-/ /g' Astral*.tre
		sed -i.bak3 's/_/ /g' Astral*.tre
		#Copy results and log to home
		if [[ $update =~ "yes" ]]; then
			cp Astral*bootstrap*.tre $path/${treepath}${type}${MISSINGPERCENT}_${SPECIESPRESENCE}/${tree}/update/species_trees/Astral
			cp Astral_boot.log $path/${treepath}${type}${MISSINGPERCENT}_${SPECIESPRESENCE}/${tree}/update/species_trees/Astral
		else
			cp Astral*bootstrap*.tre $path/${treepath}${type}${MISSINGPERCENT}_${SPECIESPRESENCE}/${tree}/species_trees/Astral
			cp Astral_boot.log $path/${treepath}${type}${MISSINGPERCENT}_${SPECIESPRESENCE}/${tree}/species_trees/Astral
		fi
	fi
fi
echo -e "\nProgress of ASTRAL run is written to Astral.log and Astral_boot.log (if MLBS was requested)..."

#Clean scratch/work directory
if [[ $PBS_O_HOST == *".cz" ]]; then
	#delete scratch
	rm -rf $SCRATCHDIR/*
else
	cd ..
	rm -r workdir07a
fi

echo -e "\nScript HybPhyloMaker7a finished...\n"