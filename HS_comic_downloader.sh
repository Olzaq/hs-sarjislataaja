#!/bin/bash
#######################################################################
# Copyright 2014 Olli Numminen
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#######################################################################

function ParseComicName
{
    COMICNAME=`echo $1 | perl -pe 's|http://.*?/(.*)/.*|\1|'`
}

###################################################

function getImageForURL
{
    imageURL=$1
    wget -q ${imageURL}

    # parse links
    htmlFile=`echo ${imageURL} | cut -f 5 -d'/'`
    comicLink=`grep --color=never "/sarjis/" ${htmlFile}`
    comicURL=`echo ${comicLink} | perl -pe 's|.*(http.*)".*|\1|'`
    ParseComicName ${imageURL}

    #parse date
    comicDate=`grep --color=never comic-date ${htmlFile}`
    comicDate=`echo ${comicDate} | perl -pe 's|.*>(.*)<.*|\1|'`
    YEAR=`echo ${comicDate} | perl -pe 's/.*(\d{4}).*/\1/'`
    MONTH=`echo ${comicDate} | perl -pe 's/\d{1,2}.(\d{1,2}).*/\1/'`
    DAY=`echo ${comicDate} | perl -pe 's/(\d{1,2}).*/\1/'`

    # extend month and date
    if [ ${#MONTH} -eq 1 ]; then
	MONTH="0${MONTH}"
    fi
    if [ ${#DAY} -eq 1 ]; then
	DAY="0${DAY}"
    fi

    # Create image directory
    COMICDIR="./${COMICNAME}/${YEAR}"
    if [ ! -d ${COMICDIR} ]; then
	mkdir -p ${COMICDIR}
    fi

    #create filename
    FILENAME="${COMICDIR}/${COMICNAME}_${YEAR}_${MONTH}_${DAY}.jpg"
    wget -nv --output-document=${FILENAME} ${comicURL}
}

########################################################

function findNextLink
{
    VANHAURL=$1
    BASELINK=`echo ${VANHAURL} | perl -pe 's|(http://.*?)/.*|\1|'`
    ParseComicName ${VANHAURL}
    htmlFile=`echo ${VANHAURL} | cut -f 5 -d'/'`
    nextLine=`grep --color=never 'title="Seuraava"' ${htmlFile}`
    nextLink=`echo ${nextLine} | perl -pe 's|.*${COMICNAME}/(.*)".*|\1|'`
    newURL="${BASELINK}/${COMICNAME}/${nextLink}"
    URL=${newURL}

    #remove temp files
    rm ${htmlFile}
}

############################################################

# CheckParameters 
if [ "$#" -ne 1 ]; then
    echo
    echo "Virhe: Anna HS URL parametrina!"
    echo "       Linkin saa näkyviin kun valitsee vanhemman sarjakuvan!"
    echo "       ESIM:"    
    echo "$0 http://www.hs.fi/viivijawagner/s1349773144978"
    echo
    exit 1;
fi

URL=$1

for (( ; ; ))
do
    getImageForURL ${URL}
    findNextLink ${URL}
    if [ ${#nextLink} -eq 0 ]; then
	echo 
	echo "Done!"
        echo
	exit 0;
    fi
done


