#!/bin/bash

TOP_DIR=`pwd`
BASEDIR=$TOP_DIR/docker
WORKAREA=$TOP_DIR

mkdir -p $WORKSPACE/Reports

trivy image --format template --template "@html.tpl" -o Reports/activemq_trivy.html --timeout 3000s --security-checks vuln  --severity HIGH,CRITICAL --input docker/Identity_Manager_*_Containers/docker-images/IDM_*_activemq.tar.gz &
trivy image --format template --template "@html.tpl" -o Reports/osp_trivy.html --timeout 3000s --security-checks vuln  --severity HIGH,CRITICAL --input docker/Identity_Manager_*_Containers/docker-images/IDM_*_osp.tar.gz &
trivy image --format template --template "@html.tpl" -o Reports/identityapplication_trivy.html --timeout 3000s --security-checks vuln  --severity HIGH,CRITICAL --input docker/Identity_Manager_*_Containers/docker-images/IDM_*_identityapplication.tar.gz &
wait

trivy image --format template --template "@html.tpl" -o Reports/identityreporting_trivy.html --timeout 3000s --security-checks vuln  --severity HIGH,CRITICAL --input docker/Identity_Manager_*_Containers/docker-images/IDM_*_identityreporting.tar.gz &
trivy image --format template --template "@html.tpl" -o Reports/identityengine_trivy.html --timeout 3000s --security-checks vuln  --severity HIGH,CRITICAL --input docker/Identity_Manager_*_Containers/docker-images/IDM_*_identityengine.tar.gz &
trivy image --format template --template "@html.tpl" -o Reports/formrenderer_trivy.html --timeout 3000s --security-checks vuln  --severity HIGH,CRITICAL --input docker/Identity_Manager_*_Containers/docker-images/IDM_*_formrenderer.tar.gz &
wait

trivy image --format template --template "@html.tpl" -o Reports/fanoutagent_trivy.html --timeout 3000s --security-checks vuln  --severity HIGH,CRITICAL --input docker/Identity_Manager_*_Containers/docker-images/IDM_*_fanoutagent.tar.gz &
trivy image --format template --template "@html.tpl" -o Reports/remoteloader_trivy.html --timeout 3000s --security-checks vuln  --severity HIGH,CRITICAL --input docker/Identity_Manager_*_Containers/docker-images/IDM_*_remoteloader.tar.gz &
trivy image --format template --template "@html.tpl" -o Reports/identityutils_trivy.html --timeout 3000s --security-checks vuln  --severity HIGH,CRITICAL --input docker/Identity_Manager_*_Containers/docker-images/IDM_*_identityutils.tar.gz &
wait

trivy image --format template --template "@html.tpl" -o Reports/idm_conf_generator_trivy.html --timeout 3000s --security-checks vuln  --severity HIGH,CRITICAL --input docker/Identity_Manager_*_Containers/docker-images/IDM_*_idm_conf_generator.tar.gz &
trivy image --format template --template "@html.tpl" -o Reports/postgres_trivy.html --timeout 3000s --security-checks vuln  --severity HIGH,CRITICAL --input docker/Identity_Manager_*_Containers/docker-images/IDM_*_postgres.tar.gz &
trivy image --format template --template "@html.tpl" -o Reports/coredns_trivy.html --timeout 3000s --security-checks vuln  --severity HIGH,CRITICAL --input docker/Identity_Manager_*_Containers/docker-images/IDM_*_coredns.tar.gz &
wait

trivy image --format template --template "@html.tpl" -o Reports/sspr_trivy.html --timeout 3000s --security-checks vuln  --severity HIGH,CRITICAL --input docker/Identity_Manager_*_Containers/docker-images/IDM_*_sspr.tar.gz &
trivy image --format template --template "@html.tpl" -o Reports/identityconsole_trivy.html --timeout 3000s --security-checks vuln  --severity HIGH,CRITICAL --input docker/Identity_Manager_*_Containers/docker-images/identityconsole_*.tar.gz &

wait

#JSON Format

trivy image --format json --timeout 3000s --security-checks vuln --severity HIGH,CRITICAL --input docker/Identity_Manager_*_Containers/docker-images/IDM_*_identityapplication.tar.gz  > Reports/IDM_identityapplication.json &
trivy image --format json --timeout 3000s --security-checks vuln --severity HIGH,CRITICAL --input docker/Identity_Manager_*_Containers/docker-images/IDM_*_sspr.tar.gz > Reports/IDM_sspr.json &
wait

trivy image --format json --timeout 3000s --security-checks vuln --severity HIGH,CRITICAL --input docker/Identity_Manager_*_Containers/docker-images/identityconsole_*.tar.gz > Reports/identityconsole.json &
trivy image --format json --timeout 3000s --security-checks vuln --severity HIGH,CRITICAL --input docker/Identity_Manager_*_Containers/docker-images/IDM_*_osp.tar.gz > Reports/IDM_osp.json &
trivy image --format json --timeout 3000s --security-checks vuln --severity HIGH,CRITICAL --input docker/Identity_Manager_*_Containers/docker-images/IDM_*_identityreporting.tar.gz > Reports/IDM_identityreporting.json &
wait

trivy image --format json --timeout 3000s --security-checks vuln --severity HIGH,CRITICAL --input docker/Identity_Manager_*_Containers/docker-images/IDM_*_identityengine.tar.gz > Reports/IDM_identityengine.json &
trivy image --format json --timeout 3000s --security-checks vuln --severity HIGH,CRITICAL --input docker/Identity_Manager_*_Containers/docker-images/IDM_*_activemq.tar.gz > Reports/IDM_activemq.json &
trivy image --format json --timeout 3000s --security-checks vuln --severity HIGH,CRITICAL --input docker/Identity_Manager_*_Containers/docker-images/IDM_*_formrenderer.tar.gz > Reports/IDM_formrenderer.json &
wait

trivy image --format json --timeout 3000s --security-checks vuln --severity HIGH,CRITICAL --input docker/Identity_Manager_*_Containers/docker-images/IDM_*_fanoutagent.tar.gz > Reports/IDM_fanoutagent.json &
trivy image --format json --timeout 3000s --security-checks vuln --severity HIGH,CRITICAL --input docker/Identity_Manager_*_Containers/docker-images/IDM_*_remoteloader.tar.gz > Reports/IDM_remoteloader.json &
trivy image --format json --timeout 3000s --security-checks vuln --severity HIGH,CRITICAL --input docker/Identity_Manager_*_Containers/docker-images/IDM_*_identityutils.tar.gz > Reports/IDM_identityutils.json &
wait

trivy image --format json --timeout 3000s --security-checks vuln --severity HIGH,CRITICAL --input docker/Identity_Manager_*_Containers/docker-images/IDM_*_idm_conf_generator.tar.gz > Reports/IDM_idm_conf_generator.json &
trivy image --format json --timeout 3000s --security-checks vuln --severity HIGH,CRITICAL --input docker/Identity_Manager_*_Containers/docker-images/IDM_*_postgres.tar.gz > Reports/IDM_postgres.json &
trivy image --format json --timeout 3000s --security-checks vuln --severity HIGH,CRITICAL --input docker/Identity_Manager_*_Containers/docker-images/IDM_*_coredns.tar.gz > Reports/IDM_coredns.json &
wait

cd $WORKSPACE
