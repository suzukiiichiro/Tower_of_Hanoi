#!/bin/bash

#入力が数値であるかを識別
if ! expr "$1" : "[0-9]*$" >&/dev/null;then
	echo "円盤の数は半角の数字である必要があります";
	exit;
fi

E_NOPARAM=86
E_BADPARAM=87   
E_NOEXIT=88
DELAY=0.3         

#円盤の数 $1:実行パラメータから渡される
DISKS=$1;

Moves=0
MWIDTH=7
MARGIN=2
basewidth=$((MWIDTH*DISKS+MARGIN));
disks1=$((DISKS-1));
spaces1="$DISKS";
spaces2=$((2*DISKS));
lastmove_t=$((DISKS-1));
#
#配列の宣言
declare -a Rod1 Rod2 Rod3
#
function repeat  {  
  local n           
  for((n=0;n<$2;n++));do
    echo -n "$1"
  done
}
function FromRod  {
  local rod summit weight sequence
  while true; do
    rod=$1
    test ${rod/[^123]/} || continue
    sequence=$(echo $(seq 0 $disks1 | tail -r ))
    for summit in $sequence; do
      eval weight=\${Rod${rod}[$summit]}
      test $weight -ne 0 &&
           { echo "$rod $summit $weight"; return; }
    done
  done
}
function ToRod  { 
  local rod firstfree weight sequence
  while true; do
    rod=$2
    test ${rod/[^123]} || continue
    
    sequence=$(echo $(seq 0 $disks1 | tail -r))
    for firstfree in $sequence; do
      eval weight=\${Rod${rod}[$firstfree]}
      test $weight -gt 0 && { (( firstfree++ )); break; }
    done
    test $weight -gt $1 -o $firstfree = 0 &&
         { echo "$rod $firstfree"; return; }
  done
}
function PrintRods  {
  local disk rod empty fill sp sequence
  tput cup 5 0
  repeat " " $spaces1
  echo -n "|"
  repeat " " $spaces2
  echo -n "|"
  repeat " " $spaces2
  echo "|"
  sequence=$(echo $(seq 0 $disks1 | tail -r))
  for disk in $sequence; do
    for rod in {1..3}; do
      eval empty=$(( $DISKS - (Rod${rod}[$disk] / 2) ))
      eval fill=\${Rod${rod}[$disk]}
      repeat " " $empty
      test $fill -gt 0 && repeat "*" $fill || echo -n "|"
      repeat " " $empty
    done
    echo
  done
  repeat "=" $basewidth   
  echo
}
#
#表示
function display(){
	#塔の表示
  PrintRods;
  first=( `FromRod $1` );
  eval Rod${first[0]}[${first[1]}]=0;
  second=( `ToRod ${first[2]} $2` );
  eval Rod${second[0]}[${second[1]}]=${first[2]};
  if [ "${Rod3[lastmove_t]}" = 1 ];then   
    tput cup 0 0;
    echo; echo "+  Final Position: $Moves moves";
		#塔の表示
    PrintRods;
  fi
  sleep $DELAY;
}
#
#ハノイの塔の実行
function dohanoi() {   
	case $1 in
		0)
			;;
		*)
			dohanoi "$(($1-1))" $2 $4 $3;
			if [ "$Moves" -ne 0 ];then
				tput cup 0 0;#上から0行目、左から0文字目にカーソルを移動
				echo; echo "+  Position after move $Moves";
			fi
			((Moves++));
			echo -n "   Next move will be:  ";
			echo $2 "-->" $3;
			display $2 $3;
			dohanoi "$(($1-1))" $4 $3 $2;
			;;
	esac
}
#
#円盤の初期化
#
function setup_arrays(){
  local elem=$((DISKS-1));
	for((n=0;n<DISKS;n++));do
		#n枚の円盤すべてを移動させるには
		#最低 2n−1回の手数がかかる
		Rod1["$elem"]=$((2*n+1));
		Rod2["$n"]=0;
		Rod3["$n"]=0;
		((elem--));
  done
}
#
#画面の初期化
#
function init(){
	#
	# tputについて
	#
	# tput setaf <色番号> #文字色を色番号にする
	# tput setab <色番号> #文字色を色番号にする
	# tput cup <y座標> <x座標> # 上からx行目左からy文字目にカーソル移動
	# tput bold #太字
	# tput clear # clearコマンドと同じ効果
	# tput sgr0 # 装飾解除
	# tput cols # ターミナルの横幅を文字数で出力
	# tput lines # ターミナルの縦幅を文字数で出力
	# tput civis # カーソル非表示
	# tput cnorm # カーソル表示
	trap "tput cnorm" 0; 	#カーソル表示
	tput civis; 					#カーソル非表示
	clear; 								#画面消去
	tput cup 0 0;					#上から0行目、左から0文字目にカーソルを移動
}
#
####################################################
# 実行
####################################################
#
# $#:実行パラメータの数
case $# in 
	#入力パラメータがひとつ
  1) 
		case $(($1>0)) in     
			#入力パラメータは1以上の数値
			1)
				#画面の初期化
				init;
				#円盤の初期化 setup_arrays <円盤の数>
				setup_arrays;
				#
				#実行
				echo; echo "+  Start Position";
				dohanoi "$DISKS" 1 3 2;
				#終了
				exit 0;
				;;
			*)
				echo "$0: 円盤の数の値が不正です";
				exit "$E_BADPARAM";
				;;
		esac
		;;
	*)
		echo "使い方: $0 N";
		echo "       \"N\" は円盤の数を指定します";
		exit "$E_NOPARAM";
	;;
esac
#
#終了
exit $E_NOEXIT;
