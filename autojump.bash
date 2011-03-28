#Copyright Joel Schaerer 2008, 2009
#This file is part of autojump

#autojump is free software: you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation, either version 3 of the License, or
#(at your option) any later version.
#
#autojump is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with autojump.  If not, see <http://www.gnu.org/licenses/>.

#This shell snippet sets the prompt command and the necessary aliases
_autojump() 
{
        local cur
        cur=${COMP_WORDS[*]:1}
        while read i
        do
            COMPREPLY=("${COMPREPLY[@]}" "${i}")
        done  < <(autojump --bash --completion $cur)
}
complete -F _autojump j
#data_dir=${XDG_DATA_HOME:-$([ -e ~/.local/share ] && echo ~/.local/share || echo ~)}
data_dir=$([ -e ~/.local/share ] && echo ~/.local/share || echo ~)
export AUTOJUMP_HOME=${HOME}
if [[ "$data_dir" = "${HOME}" ]]
then
    export AUTOJUMP_DATA_DIR=${data_dir}
else
    export AUTOJUMP_DATA_DIR=${data_dir}/autojump
fi
if [ ! -e "${AUTOJUMP_DATA_DIR}" ]
then
    mkdir "${AUTOJUMP_DATA_DIR}"
    mv ~/.autojump_py "${AUTOJUMP_DATA_DIR}/autojump_py" 2>>/dev/null #migration
    mv ~/.autojump_py.bak "${AUTOJUMP_DATA_DIR}/autojump_py.bak" 2>>/dev/null
    mv ~/.autojump_errors "${AUTOJUMP_DATA_DIR}/autojump_errors" 2>>/dev/null
fi

AUTOJUMP='{ [[ "$AUTOJUMP_HOME" == "$HOME" ]] && (autojump -a "$(pwd -P)"&)>/dev/null 2>>${AUTOJUMP_DATA_DIR}/autojump_errors;} 2>/dev/null'
cdir="${AUTOJUMP_DATA_DIR}/.autojump_pwds"
is_cdir_valid='touch ${cdir}'
uniq_by_1st_field='{ awk '\''!x[$1]++'\'' ${cdir} > ${cdir}.new ; mv ${cdir}.new ${cdir};} 2>>/dev/null'
update_path_by_pid='( [ `grep -c $$ ${cdir}` -gt 0 ] && sed -i "s_($$\s*)\S*_\1`pwd -P`_" ${cdir} )'
add_path_with_pid='( echo "$$ `pwd -P`" >> ${cdir} )'
#AUTOJUMP_writePWD='{ ${update_path_by_pid} || ${add_path_with_pid} } 2>/dev/null'
AUTOJUMP_writePWD=' if [ `grep -c $$ ${cdir}` -gt 0 ]; then sed -rien "s_($$\s*)\S*_\1`pwd`_" ${cdir}; else echo "$$ `pwd -P`" >> ${cdir}; fi '
if [[ ! $PROMPT_COMMAND =~ autojump ]]; then
  export PROMPT_COMMAND="${PROMPT_COMMAND:-:} ; $AUTOJUMP ;\
    ${is_cdir_valid}; ${uniq_by_1st_field}; ${AUTOJUMP_writePWD}"
fi 
alias jumpstat="autojump --stat"
function j {
  new_path="$(autojump $@)";
  if [ -n "$new_path" ]; then
    echo -e "\\033[31m${new_path}\\033[0m";
    cd "$new_path";
  else
    false;
  fi
}
