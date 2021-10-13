#!/bin/bash

main(){
    readonly DOCKER_PATH=/usr/bin/docker
    readonly IMAGE_WITHOUT_TAG=reademption
    readonly IMAGE=tillsauerwein/reademption:1.0.5
    readonly CONTAINER_NAME=reademption_container
    readonly READEMPTION_ANALYSIS_FOLDER=reademption_analysis
    readonly FTP_SOURCE=https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/210/855/GCF_000210855.2_ASM21085v2
    readonly MAPPING_PROCESSES=6
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
    build_reademption_image
    create_running_container
    ## Running the analysis:
    create_reademtption_folder
    download_reference_sequences
    download_annotation
    download_and_subsample_reads
    align_reads
    build_coverage_files
    run_gene_quanti
    run_deseq
    copy_analysis_to_local


    ## inspecting the container:
    #build_reademption_image_no_cache
    #execute_command_ls
    #execute_command_tree
    #show_containers
    #stop_container
    #start_container
    #remove_all_containers

}

## Running analysis

build_reademption_image(){
    $DOCKER_PATH build -f Dockerfile -t $IMAGE .
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

main $@