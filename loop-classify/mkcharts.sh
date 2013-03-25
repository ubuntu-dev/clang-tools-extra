BENCH=$1

if [[ $2 == "run" ]] ; then
    if [[ ${BENCH} == "coreutils" ]] ; then
        FILES=$(echo /Users/thomas/Downloads/coreutils-8.21/src/{base64.c,basename.c,cat.c,chcon.c,chgrp.c,chmod.c,chown-core.c,chown.c,chroot.c,cksum.c,comm.c,copy.c,cp-hash.c,cp.c,csplit.c,cut.c,date.c,dd.c,df.c,dircolors.c,dirname.c,du.c,echo.c,env.c,expand.c,expr.c,extent-scan.c,factor.c,false.c,find-mount-point.c,fmt.c,fold.c,getlimits.c,group-list.c,groups.c,head.c,hostid.c,hostname.c,id.c,install.c,join.c,kill.c,lbracket.c,libstdbuf.c,link.c,ln.c,logname.c,ls-dir.c,ls-ls.c,ls-vdir.c,ls.c,make-prime-list.c,mkdir.c,mkfifo.c,mknod.c,mktemp.c,mv.c,nice.c,nl.c,nohup.c,nproc.c,numfmt.c,od.c,operand2sig.c,paste.c,pathchk.c,pinky.c,pr.c,printenv.c,printf.c,prog-fprintf.c,ptx.c,pwd.c,readlink.c,realpath.c,relpath.c,remove.c,rm.c,rmdir.c,runcon.c,seq.c,setuidgid.c,shred.c,shuf.c,sleep.c,sort.c,split.c,stat.c,stdbuf.c,stty.c,sum.c,sync.c,tac.c,tail.c,tee.c,test.c,timeout.c,touch.c,tr.c,true.c,truncate.c,tsort.c,tty.c,uname-arch.c,uname-uname.c,uname.c,unexpand.c,uniq.c,unlink.c,uptime.c,users.c,version.c,wc.c,who.c,whoami.c,yes.c})
        INCLUDES=-I/Users/thomas/Downloads/coreutils-8.21/lib/ 
    elif [[ ${BENCH} == "cBench" ]] ; then
        # find ~/Downloads/cBench15032013/ -name '*.c' >all.txt
        # ninja && bin/loop-classify $(find ~/Downloads/cBench15032013/ -name '*.c') -loop-stats -- 2>/dev/null | grep 'Error while processing' | cut -d' ' -f4 >excl.txt
        FILES=$(comm -23 all.txt excl.txt)
    fi
    echo "BENCH\t$BENCH">$BENCH.stats

    ninja || exit 1
    bin/loop-classify $FILES -loop-stats -- -w $INCLUDES 2>$BENCH.stats
fi

export LC_ALL=en_US
CLASSES=$(cat "${BENCH}.stats" | egrep '^(DO|FOR|WHILE)\t' | awk 'function stripl(s) { return substr(s, 0, length(s)-1) } { printf "%s/%s,", stripl($3), $1; } END { print ""; }' | sed 's/,$//')
EMPTYBODY=$(cat "${BENCH}.stats" | egrep '^ANY-EMPTYBODY' | awk 'function stripl(s) { return substr(s, 0, length(s)-1) } { printf "%s/%s,", stripl($3), $1; SUM=SUM+(stripl($3)) } END { printf "%.1f/REST\n", 100-SUM; }' | sed 's/,$//')
ADA=$(cat "${BENCH}.stats" | egrep '^FOR-ADA' | awk 'function stripl(s) { return substr(s, 0, length(s)-1) } { printf "%s/%s,", stripl($4), $1; SUM=SUM+(stripl($4)) } END { printf "%.1f/REST\n", 100-SUM; }' | sed 's/,$//' | sed 's/_/\\_/g')
ADA_DETAIL=$(cat "${BENCH}.stats" | egrep '^FOR-' | awk 'function stripl(s) { return substr(s, 0, length(s)-1) } { printf "%s/%s,", stripl($4), $1; SUM=SUM+(stripl($4)) } END { printf "%.1f/REST\n", 100-SUM; }' | sed 's/,$//' | sed 's/_/\\_/g')

cat <<EOF >"${BENCH}.tex"
\documentclass{article}

\usepackage[a4paper,landscape]{geometry}
\usepackage{pgf-pie}
\usetikzlibrary{shadows}

\title{$BENCH}

\begin{document}
\maketitle
\section{Plain}
\begin{verbatim}
$(cat "${BENCH}.stats")
\end{verbatim}
\section{Loop Statements}
\begin{tikzpicture}
\pie[radius=6]{$CLASSES}
\end{tikzpicture}
\section{Empty Body}
\begin{tikzpicture}
\pie[radius=6]{$EMPTYBODY}
\end{tikzpicture}
\section{Ada-style FOR Loops}
\begin{tikzpicture}
\pie[radius=6]{$ADA}
\end{tikzpicture}
\section{Ada-style FOR Loops (exclusion details)}
\begin{tikzpicture}
\pie[text=pin,radius=6,rotate=270]{$ADA_DETAIL}
\end{tikzpicture}
\end{document}
EOF
pdflatex "${BENCH}.tex" >/dev/null && open "${BENCH}.pdf" #convert -density 600x600 texput.pdf -quality 90 -resize 800x600 pic.png && open pic.png
