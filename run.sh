#!/bin/bash

main(){
    readonly DOCKER_PATH=/usr/bin/docker
    readonly IMAGE_WITHOUT_TAG=reademption
    readonly IMAGE=tillsauerwein/reademption:1.0.5
    readonly CONTAINER_NAME=reademption_container
    readonly READEMPTION_ANALYSIS_FOLDER=reademption_analysis
    readonly FTP_SOURCE=https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/210/855/GCF_000210855.2_ASM21085v2
    readonly MAPPING_PROCESSES=1
    readonly COVERAGE_PROCESSES=6
    readonly GENE_QUANTI_PROCESSES=6
    readonly LOCAL_OUTOUT_PATH="."



    if [ ${#@} -eq 0 ]
    then
        echo "Specify function to call or 'all' for running all functions"
        echo "Avaible functions are: "
        grep "(){" run.sh | grep -v "^all()" |  grep -v "^main(){" |  grep -v "^#"  | grep -v 'grep "(){"' | sed "s/(){//"
    else
        "$@"
    fi
}

all(){
    ## Creating image and container:
    pull_image
    create_running_container
    ## Running the analysis:
    create_reademtption_folder
    copy_reads_and_genome_and_annotation
    align_reads
    #build_coverage_files
    #run_gene_quanti
    #run_deseq

    #copy_analysis_to_local


    ## inspecting the container:
    #build_reademption_image_no_cache
    #execute_command_ls
    #tree
    #show_containers
    #stop_container
    #start_container
    #remove_all_containers

}

## Running analysis


pull_image(){
    $DOCKER_PATH pull $IMAGE
}

# creates a running container with bash
create_running_container(){
    $DOCKER_PATH run --name $CONTAINER_NAME -it -d $IMAGE bash
}

# create the reademption input and outputfolders inside the container
create_reademtption_folder(){
    $DOCKER_PATH exec $CONTAINER_NAME \
      reademption create -f $READEMPTION_ANALYSIS_FOLDER
}

copy_reads_and_genome_and_annotation(){
  $DOCKER_PATH cp data/library_one_p1.fq ${CONTAINER_NAME}:/root/${READEMPTION_ANALYSIS_FOLDER}/input/reads
  $DOCKER_PATH cp data/library_one_p2.fq ${CONTAINER_NAME}:/root/${READEMPTION_ANALYSIS_FOLDER}/input/reads
  $DOCKER_PATH cp data/GRCh38.p10.genome_short.fa ${CONTAINER_NAME}:/root/${READEMPTION_ANALYSIS_FOLDER}/input/reference_sequences/human.fa
  $DOCKER_PATH cp data/gencode.v27.annotation_short.gff3 ${CONTAINER_NAME}:/root/${READEMPTION_ANALYSIS_FOLDER}/input/annotations/human.gff
}

align_reads(){
    $DOCKER_PATH exec $CONTAINER_NAME \
      reademption align \
			-p ${MAPPING_PROCESSES} \
			--paired_end \
			--progress \
			--fastq \
			--split \
			     -f $READEMPTION_ANALYSIS_FOLDER

}

build_coverage_files(){
    $DOCKER_PATH exec $CONTAINER_NAME \
      reademption coverage \
      -p $COVERAGE_PROCESSES \
      -f $READEMPTION_ANALYSIS_FOLDER

    echo "coverage done"
}

run_gene_quanti(){
    $DOCKER_PATH exec $CONTAINER_NAME \
      reademption gene_quanti \
      -p $GENE_QUANTI_PROCESSES \
         -f $READEMPTION_ANALYSIS_FOLDER
    echo "gene quanti done"
}



run_deseq(){
    $DOCKER_PATH exec $CONTAINER_NAME \
			reademption deseq \
			--libs library_one \
			--conditions replicate1 \
         -f $READEMPTION_ANALYSIS_FOLDER
    echo "deseq done"
}

copy_analysis_to_local(){
  $DOCKER_PATH cp ${CONTAINER_NAME}:/root/${READEMPTION_ANALYSIS_FOLDER} ${LOCAL_OUTOUT_PATH}
}

## Inspecting

# execute a command and keep the container running
# only works when container is running
build_reademption_image_no_cache(){
    $DOCKER_PATH build --no-cache -f Dockerfile -t $IMAGE_WITHOUT_TAG .
}


execute_command_ls(){
    $DOCKER_PATH exec $CONTAINER_NAME ls
}

show_reademption_version(){
    $DOCKER_PATH exec $CONTAINER_NAME reademption --version
}

# execute a command and keep the container running
# only works when container is running
tree(){
    $DOCKER_PATH exec $CONTAINER_NAME tree $READEMPTION_ANALYSIS_FOLDER
}


show_containers(){
   $DOCKER_PATH ps -a
}

# stop the container
stop_container(){
    $DOCKER_PATH stop $CONTAINER_NAME
}

# start container and keep it runnning
start_container(){
    $DOCKER_PATH start $CONTAINER_NAME
}


remove_all_containers(){
  $DOCKER_PATH container prune
}

main $@