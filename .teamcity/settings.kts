import jetbrains.buildServer.configs.kotlin.v2018_1.*
import jetbrains.buildServer.configs.kotlin.v2018_1.buildFeatures.swabra
import jetbrains.buildServer.configs.kotlin.v2018_1.buildSteps.maven
import jetbrains.buildServer.configs.kotlin.v2018_1.buildSteps.script
import jetbrains.buildServer.configs.kotlin.v2018_1.triggers.vcs
import jetbrains.buildServer.configs.kotlin.v2018_1.vcs.GitVcsRoot

/*
The settings script is an entry point for defining a TeamCity
project hierarchy. The script should contain a single call to the
project() function with a Project instance or an init function as
an argument.

VcsRoots, BuildTypes, Templates, and subprojects can be
registered inside the project using the vcsRoot(), buildType(),
template(), and subProject() methods respectively.

To debug settings scripts in command-line, run the

    mvnDebug org.jetbrains.teamcity:teamcity-configs-maven-plugin:generate

command and attach your debugger to the port 8000.

To debug in IntelliJ Idea, open the 'Maven Projects' tool window (View
-> Tool Windows -> Maven Projects), find the generate task node
(Plugins -> teamcity-configs -> teamcity-configs:generate), the
'Debug' option is available in the context menu for the task.
*/

version = "2018.1"

project {
    description = "Contains all other projects"

    features {
        feature {
            id = "PROJECT_EXT_1"
            type = "ReportTab"
            param("startPage", "coverage.zip!index.html")
            param("title", "Code Coverage")
            param("type", "BuildReportTab")
        }
    }

    cleanup {
        preventDependencyCleanup = false
    }

    subProject(AuthServer)
}


object AuthServer : Project({
    name = "auth-server"

    vcsRoot(AuthServer_FeatureMultiFactor)

    buildType(AuthServer_DEV)

    features {
        feature {
            id = "PROJECT_EXT_4"
            type = "sonar-qube"
            param("password", "zxx0feb335798e7f083")
            param("name", "SonarQube kwsoebapu01")
            param("id", "bede5183-447f-4427-8f7c-a5b0c7c15824")
            param("login", "admin")
            param("url", "http://kwsoebapu01.alfa.bank.int:9000/sonarqube/")
        }
    }
})

object AuthServer_DEV : BuildType({
    name = "feature/multi-factor"

    params {
        param("env.app_name", "%maven.project.name%-%maven.project.version%")
        param("env.deployment_server", "digitapu02.alfa.bank.int")
        param("env.http_server_port", "58091")
        param("env.team", "5_dev_ops")
        param("env.project", "auth-server")
        password("env.user_password", "credentialsJSON:3d6bd1f6-76da-4ffc-8ee3-8f376fc39db3")
        param("env.server_port", "58092")
        param("env.branch", "feature")
        param("env.username", "v.perlovskiy")
    }

    vcs {
        root(AuthServer_FeatureMultiFactor)
    }

    steps {
        maven {
            name = "clean-install-with-deploy-profile"
            goals = "clean install -DskipTests=true"
            runnerArgs = "-P withDeploy"
            mavenVersion = bundled_3_3()
            param("teamcity.tool.jacoco", "%teamcity.tool.jacoco.DEFAULT%")
        }
        script {
            name = "Copy artifact, conf files and start service"
            workingDir = "%teamcity.agent.work.dir%"
            scriptContent = """
                #!/bin/bash
                echo "Update OS repo"
                apt update && apt-get -f install sshpass
                # Add a user to Linux system
                adduser %env.username% --gecos "First Last,RoomNumber,WorkPhone,HomePhone" --disabled-password --force-badname
                echo "Switch user"
                su - %env.username% -c 'rm -f /home/%env.username%/.ssh/*'
                echo "Generate key pair"
                su - %env.username% -c 'ssh-keygen -t rsa -f /home/%env.username%/.ssh/id_rsa -q -P ""'
                echo "Copy ssh key to remote server"
                su - %env.username% -c 'sshpass -p "%env.user_password%" ssh-copy-id -o StrictHostKeyChecking=no %env.username%@%env.deployment_server%'
                echo "Create folders for service deployment as sudo user"
                su - %env.username% -c 'ssh -T -o "StrictHostKeyChecking=no" "%env.username%@%env.deployment_server%"' <<'ENDSSH'
                sudo su - sab
                echo ${'$'}USER
                echo %env.app_name%
                mkdir -p /app/uat/%env.team%/%env.project%
                mkdir -p /app/uat/%env.team%/%env.project%/%env.branch%/
                ENDSSH
                echo "Create folders structure in maintainer home directory"
                su - %env.username% -c 'ssh -T -o "StrictHostKeyChecking=no" "%env.username%@%env.deployment_server%"' <<'ENDSSH'
                mkdir -p /home/%env.username%/%env.project%/%env.branch%
                mkdir -p /home/%env.username%/%env.project%/%env.branch%/config
                mkdir -p /home/%env.username%/%env.project%/%env.branch%/public
                ENDSSH
                echo "Secure copy artefact to ENV server"
                su - %env.username% -c 'scp -rp "%teamcity.build.checkoutDir%/assembly/%env.app_name%/"'*'".jar" %env.username%@%env.deployment_server%:"/home/%env.username%/%env.project%/%env.branch%"'
                su - %env.username% -c 'scp -rp "/opt/buildagent/work/auth.sh" %env.username%@%env.deployment_server%:"/home/%env.username%/%env.project%/%env.branch%/auth.sh"'
                su - %env.username% -c 'scp -rp "%teamcity.build.checkoutDir%/config" %env.username%@%env.deployment_server%:"/home/%env.username%/%env.project%/%env.branch%/"'
                su - %env.username% -c 'scp -rp "%teamcity.build.checkoutDir%/public" %env.username%@%env.deployment_server%:"/home/%env.username%/%env.project%/%env.branch%/"'
                echo "Move artifact and config files into target directory"
                su - %env.username% -c 'ssh -T -o "StrictHostKeyChecking=no" "%env.username%@%env.deployment_server%"' <<'ENDSSH'
                sudo su - sab
                echo ${'$'}USER
                
                ENV_FILE_LOCATION_FIRST="/home/%env.username%/%env.project%/%env.branch%/config/connection.properties"
                ENV_FILE_LOCATION_SECOND="/app/uat/%env.team%/%env.project%/%env.branch%/config/connection.properties"
                path_to_jar=${'$'}(find /app/uat/%env.team%/%env.project% -type f -name "*.jar" -print)
                echo "${'$'}path_to_jar"
                
                if [ -f "${'$'}ENV_FILE_LOCATION_FIRST" ] || [ -f "${'$'}ENV_FILE_LOCATION_SECOND" ];
                then
                    echo "File:: connection.properties exist."
                    cd /app/uat/%env.team%/%env.project%/%env.branch%/
                    sh /app/uat/%env.team%/%env.project%/%env.branch%/auth.sh stop
                    find /app/uat/%env.team%/%env.project%/ -maxdepth 5 -type f \( ! -iname "connection.properties" \) -exec rm -vf {} \;
                else
                    echo "File:: connection.properties does not exist."
                    cd /app/uat/%env.team%/%env.project%/%env.branch%/
                    sh /app/uat/%env.team%/%env.project%/%env.branch%/auth.sh stop
                    find /app/uat/%env.team%/%env.project%/ -maxdepth 5 -type f \( ! -iname "application.properties" ! -iname "c3p0-config.xml" \) -exec rm -vf {} \;
                fi
                
                mkdir -p /app/uat/%env.team%/%env.project%
                mkdir -p /app/uat/%env.team%/%env.project%/%env.branch%/
                mkdir -p /app/uat/%env.team%/%env.project%/%env.branch%/log
                
                cp -rn /home/%env.username%/%env.project%/%env.branch%/* /app/uat/%env.team%/%env.project%/%env.branch%/
                sh /app/uat/%env.team%/%env.project%/%env.branch%/auth.sh start "${'$'}path_to_jar" %env.server_port% %env.http_server_port%
                ENDSSH
            """.trimIndent()
        }
        step {
            name = "sonar"
            type = "sonar-plugin"
            param("additionalParameters", "/d:sonar.verbose=true")
            param("sonarServer", "bede5183-447f-4427-8f7c-a5b0c7c15824")
        }
        script {
            name = "Clean after deployment"
            scriptContent = """
                #!/bin/bash
                echo "Post service deployment clean user home directory"
                su - %env.username% -c 'ssh -o "StrictHostKeyChecking=no" "%env.username%@%env.deployment_server%"' <<'ENDSSH'
                echo ${'$'}USER
                rm -r /home/%env.username%/%env.project%
                rm -r /home/%env.username%/.ssh/
                ENDSSH
            """.trimIndent()
        }
    }

    triggers {
        vcs {
            branchFilter = ""
        }
    }

    features {
        swabra {
        }
    }
})

object AuthServer_FeatureMultiFactor : GitVcsRoot({
    name = "feature/multi-factor"
    url = "ssh://git@kgtlabapu01.alfa.bank.int:7999/mab/auth-server.git"
    branch = "refs/heads/feature/multi-factor"
    authMethod = uploadedKey {
        uploadedKey = "id_rsa"
    }
})
