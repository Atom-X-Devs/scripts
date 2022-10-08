import os

def mergeCAF(x,path):
    os.system("git fetch "+x)
    os.system("git merge -s ours --no-commit --allow-unrelated-histories FETCH_HEAD")
    os.system("git read-tree --prefix="+path+" -u FETCH_HEAD")
    mas = path+": Initial tfa98xx Driver Import from CAF "+branch
    os.system("git commit -s -m '"+mas+"'")

branch = input("Enter tfa98xx branch: ")
tfa98xx = "http://git.codelinaro.org/external/mas/tfa98xx "+branch

mergeCAF(tfa98xx,"techpack/audio/asoc/codecs/tfa9874")
