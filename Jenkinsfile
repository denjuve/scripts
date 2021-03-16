
node {

stage('1') {
//    sh "git config --global http.sslVerify false"
//    sh 'rm -rf repo'
//	sh "git clone -b ${params.ci_branch_mon} https://$u5g:$p5g@5g-transformer.eu/git/5g-transformer.5gt-ci repo"
    git(
       branch: "${params.ci_branch_mon}",
       //"${params.BRANCH}",
       //"$git_branch_mon",
       //'nbl',
//       url: 'https://5growth.eu/git/5growth.5gr-ci',
       url: 'https://github.com/denjuve/scripts',
//       credentialsId: '5gt-ci',
    )

