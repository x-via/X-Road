#!/bin/bash

# To-do:
# args --all to deploy all packages to artifactory
# Directory with version in RHEL path. Ex.: https://artifactory.niis.org/ui/native/xroad-release-rpm/rhel/7/
COMPONENT="main"
UBUNTU_RELEASE_NAME="current"
UBUNTU_VERSION=""
REDHAT_VERSION=""
UPLOAD_UBUNTU=false
UPLOAD_REDHAT=false

showHelp() {
		echo "Uso: $0 [argumentos]"
		echo ""
		echo "Argumentos para $0:"
		echo " -u, --ubuntu       Informe a versão do Ubuntu, valores disponíveis: 20, 22 e 24. Ex.: $0 -u 20 ou $0 --ubuntu 20"
		echo " -rhel, --redhat    Informe a versão do Red Hat, valores disponíveis: 7, 8 e 9. Ex.: $0 -rhel 8 ou $0 --redhat 8"
		echo " -h, --help         Informações de ajuda e dos argumentos."
}

if [ -z "$*" ]
then
		echo "*** Erro: Nenhum argumento informado, utilize $0 -h ou $0 --help para obter ajuda." 1>&2
		exit 1
else
		while [ ! -z "$1" ]; do
			case "$1" in
				--ubuntu|-u)
						shift
						if [ "$1" = "20" ] || [ "$1" = "20.04" ]; then
							UPLOAD_UBUNTU=true
							UBUNTU_VERSION="ubuntu20.04"
							UBUNTU_RELEASE_NAME="focal-$UBUNTU_RELEASE_NAME"
						elif [ "$1" = "22" ] || [ "$1" = "22.04" ]; then
							UPLOAD_UBUNTU=true
							UBUNTU_VERSION="ubuntu22.04"
							UBUNTU_RELEASE_NAME="jammy-$UBUNTU_RELEASE_NAME"
            			elif [ "$1" = "24" ] || [ "$1" = "24.04" ]; then
							UPLOAD_UBUNTU=true
							UBUNTU_VERSION="ubuntu24.04"
							UBUNTU_RELEASE_NAME="jammy-$UBUNTU_RELEASE_NAME"
						else
							echo "*** Erro: A versão \"$1\" do Ubuntu informada é inválida, digite $0 -h para obter ajuda." 1>&2
							exit 1
						fi
						;;
				--redhat|-rhel)
						shift
						if [ "$1" = "7" ]; then
							UPLOAD_REDHAT=true
							REDHAT_VERSION="7"
						elif [ "$1" = "8" ]; then
							UPLOAD_REDHAT=true
							REDHAT_VERSION="8"
						elif [ "$1" = "9" ]; then
							UPLOAD_REDHAT=true
							REDHAT_VERSION="9"
						else
							echo "*** Erro: A versão \"$1\" do Red Hat informada é inválida, digite $0 -h para obter ajuda." 1>&2
							exit 1
						fi
						;;
				--help|-h)
						shift
						showHelp
						exit 0
						;;
				*)
						echo "*** Erro: Argumentos inválidos: $1" 1>&2
						exit 1
						;;
			esac
		shift
		done
fi

if [ "$UPLOAD_UBUNTU" = true ]; then
	echo "Realizando upload dos pacotes do Ubuntu [$UBUNTU_VERSION - $UBUNTU_RELEASE_NAME]"
	echo ""
	PACKAGES_DIRECTORY="./packages/build/$UBUNTU_VERSION/"
	PACKAGES_DIRECTORY_SEARCH="$PACKAGES_DIRECTORY*"

	for FILE in $PACKAGES_DIRECTORY_SEARCH
	do
		CURRENT_FILENAME=$(basename $FILE)
		RELATIVE_ARCHITECTURE=$(echo $CURRENT_FILENAME | awk -F\\${UBUNTU_VERSION}_ '{print $2}')
		DEBIAN_PACKAGE_NAME=$(echo "$CURRENT_FILENAME" | sed "s/_$RELATIVE_ARCHITECTURE/.deb/g")
		ARCHITECTURE=$(echo $RELATIVE_ARCHITECTURE | sed "s/.deb//g")

		curl -H "Authorization: Bearer $ARTIFACTORY_TOKEN" -XPUT "https://rw3tecnologia.jfrog.io/artifactory/xvia-debian-local/pool/main/x/xroad/$DEBIAN_PACKAGE_NAME;deb.distribution=$UBUNTU_RELEASE_NAME;deb.component=$COMPONENT;deb.architecture=$ARCHITECTURE;" -T $FILE
	done
fi

if [ "$UPLOAD_REDHAT" = true ]; then
	echo "Realizando upload dos pacotes do RedHat $REDHAT_VERSION"
	echo ""
	ARCHITECTURES_DIRECTORY="./packages/build/rhel/$REDHAT_VERSION/"
	LIST_ARCHITECTURES="$ARCHITECTURES_DIRECTORY*"

	for ARCHITECTURE in $LIST_ARCHITECTURES
	do
		CURRENT_ARCHITECTURE=$(basename $ARCHITECTURE)
		PACKAGES_DIRECTORY_SEARCH="$ARCHITECTURES_DIRECTORY$CURRENT_ARCHITECTURE/*"
			for FILE in $PACKAGES_DIRECTORY_SEARCH
			do
				RPM_PACKAGE_NAME=$(basename $FILE)
				PACKAGE_NAME_WITH_VERSION=$(basename $RPM_PACKAGE_NAME .el$REDHAT_VERSION.$CURRENT_ARCHITECTURE.rpm | sed 's/\.[^.]*$//g')
				PACKAGE_NAME=$(echo $PACKAGE_NAME_WITH_VERSION | sed 's/-[0-9].*$//g')
				PACKAGE_VERSION=$(echo $PACKAGE_NAME_WITH_VERSION | sed "s/$PACKAGE_NAME-//g")
				# PATH_TO_METADATA_ROOT="$PACKAGE_NAME/$PACKAGE_VERSION/$CURRENT_ARCHITECTURE/$RPM_PACKAGE_NAME"
				# PATH_TO_METADATA_ROOT="rhel/$REDHAT_VERSION/$CURRENT_ARCHITECTURE/$RPM_PACKAGE_NAME"
				# PATH_TO_METADATA_ROOT="$RPM_PACKAGE_NAME"
				PATH_TO_METADATA_ROOT="rhel/$REDHAT_VERSION/current/$RPM_PACKAGE_NAME"

				curl -H "Authorization: Bearer $ARTIFACTORY_TOKEN" -XPUT "https://rw3tecnologia.jfrog.io/artifactory/xvia-release-rpm/$PATH_TO_METADATA_ROOT" -T $FILE
			done
	done
fi
