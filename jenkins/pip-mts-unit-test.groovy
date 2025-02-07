/***********************************************************************
 * Jenkins Pipeline Script
 * -----------------------
 * Project Name: mts unit test
 * Description: jenkins unit test fot pymobiledevice3
 * Author: lunight
 * Date: [2025-01-21]
 * Version: 1.0
 * Notes: https://github.com/doronz88/pymobiledevice3
*********************************************************************** */

pipeline {

   agent any
    environment {
        WORKSPACE_PATH = "${WORKSPACE}/XXXXX/"  
        SCHEME = "XXXXX"         
        PROJECT_PATH = "XXXXX.xcworkspace"
        TEST_DESTINATION = "platform=iOS,id=XXXXXXXXXX-XXXXXXXXXX"
        CODE_SIGN_IDENTITY="Apple Development: lunight (XXXXXXXXXX)"
        PROVISIONING_PROFILE_SPECIFIER = "XXXXXXXXXX"
        TUNNEL_PORT = "12345 // 터널 포트 설정"
        BUNDLE_ID = "com.bundleid" // 번들 아이디 설정
    }
    stages {
        stage('Setup') {
            steps {
                script {
                    echo '🌟🌟🌟 Env setting ____________________________________________🌟🌟🌟🌟🌟🌟🌟🌟🌟🌟'
                    def fastlaneResult = sh(script: """
                    export TERM=xterm
                    #!/bin/zsh -l
                    cd <project_path>
                    bundle exec fastlane update_version_test
                    """, returnStatus: true)

                    if(fastlaneResult != 0) {
                        env.ERROR_MESSAGE = "FASTLANE_ERROR : FAILED(bundle exec fastlane update_version(${exitCode}))"
                        currentBuild.result = 'FAILURE' // 빌드 실패 상태 설정
                        error("${env.ERROR_MESSAGE}") // 명시적 빌드 중단
                    }else{
                        echo '🌟🌟🌟 Env finish :) ___________________________________________________🌟🌟🌟🌟🌟🌟🌟🌟🌟🌟'
                    }
                }
            }
        }
         stage('pod install') {
            steps {
                echo '🚀🚀🚀 Env setting ____________________________________________🚀🚀🚀🚀🚀🚀🚀🚀'
                sh """
                #!/bin/zsh -l
                cd <project_path>
                export LC_ALL=en_US.UTF-8
                export LANG=en_US.UTF-8
                export LANGUAGE=en_US.UTF-8
                locale
                ./pod_install.sh
                """
                echo '🚀🚀🚀 Env finish :) ___________________________________________________🚀🚀🚀🚀🚀🚀🚀🚀'
            }
        }
        stage('Set Environment and Mount DDI') {
            steps {
                sh '''
                export TERM=xterm
                echo "xxxxxx" | sudo -S pymobiledevice3 mounter auto-mount > mount.log 2>&1 || echo "DDI already mounted"
                '''
            }
        }
        stage('Create Tunnel') {
            steps {
                sh '''
                export TERM=xterm
                echo "Creating tunnel..."
                echo "xxxxxxx" | sudo -S pymobiledevice3 usbmux forward ${TUNNEL_PORT} ${TUNNEL_PORT} > tunnel.log 2>&1 &
                '''
            }
        }
        stage('install') {
            steps {
                    sh '''
                    cd ${WORKSPACE_PATH}
                    xcodebuild build \
                        -workspace "${WORKSPACE_PATH}${PROJECT_PATH}" \
                        -scheme "${SCHEME}" \
                        -destination "${TEST_DESTINATION}" \
                        -derivedDataPath ./build \
                        DEBUG_INFORMATION_FORMAT="dwarf-with-dsym" \
                        | xcpretty
                    '''
            }
        }
        stage('Start Tunneld') {
            steps {
                sh '''
                echo "Starting Tunneld..."
                nohup echo "xxxxxxx" | sudo -S python3 -m pymobiledevice3 remote tunneld > tunneld.log 2>&1 &
                '''
            }
        }
        stage('Run on Device') {
             steps {
                script {
                    // Shell 명령 실행 및 반환 코드 저장
                    // ios-deploy --justlaunch --id 00008110-00194C8A2222801E --bundle ./build/Build/Products/Debug-iphoneos/NamuhSmart.app 
                   sh '''
                   export TERM=xterm
                    echo "Launching app on device..."
                    echo "xxxxxxx" | sudo -S pymobiledevice3 developer dvt launch ${BUNDLE_ID}
                    '''
                }
            }
        }
        stage('Capture Logs') {
            steps {
                sh '''
                export TERM=xterm
                echo "Capturing logs..."
                echo "xxxxxxx" | sudo -S pymobiledevice3 syslog live -m ${BUNDLE_ID}
                '''
            }
        }
        // stage('Verify dSYM') {
        //     steps {
        //         sh '''
        //         cd ${WORKSPACE_PATH}
        //         dwarfdump ./build/Build/Products/Debug-iphoneos/xxxxxxxxxx.app.dSYM || echo "Invalid dSYM file"
        //         '''
        //     }
        // }
        // stage('Collect Logs') {
        //     steps {
        //         sh '''
        //         idevicesyslog > device_logs.txt || echo "Failed to fetch device logs"
        //         '''
        //     }
        // }
    }
    post {
        always {
            sh '''
            export TERM=xterm
            echo "Stopping Tunneld..."
            echo "xxxx" | sudo -S pkill -f "pymobiledevice3 remote tunneld"
            '''
            sh '''
            export TERM=xterm
            echo "Killing log capture..."
            echo "xxxx" | sudo -S pkill -f "pymobiledevice3 syslog live"
            '''
        }
        success {
            script {
                echo "✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅"
                echo "JENKINS PIPELINE(SUCCESS)"
                echo "✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅"
            }
        }
        failure {
            script {
                echo "❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌"
                echo "JENKINS PIPELINE(FAILED) "
                echo "❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌"
            }
        }
        // unstable {
        // }
        // changed {
        // }
    }
}
