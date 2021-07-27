import os

def mergeCAF(x,path):
    os.system("git fetch "+x)
    os.system("git merge -s ours --no-commit --allow-unrelated-histories FETCH_HEAD")
    os.system("git read-tree --prefix="+path+" -u FETCH_HEAD")
    mas = path+": Initial merge from "+tag
    os.system("git commit -s -m '"+mas+"'")

tag = input("Enter tag: ")
audio = "https://source.codeaurora.org/quic/la/platform/vendor/opensource/audio-kernel "+tag
qcacld = "https://source.codeaurora.org/quic/la/platform/vendor/qcom-opensource/wlan/qcacld-3.0/ "+tag
fwapi = "https://source.codeaurora.org/quic/la/platform/vendor/qcom-opensource/wlan/fw-api/ "+tag
qcacmn = "https://source.codeaurora.org/quic/la/platform/vendor/qcom-opensource/wlan/qca-wifi-host-cmn/ "+tag

mergeCAF(audio,"techpack/audio")
mergeCAF(qcacld,"drivers/staging/qcacld-3.0")
mergeCAF(fwapi,"drivers/staging/fw-api")
mergeCAF(qcacmn,"drivers/staging/qca-wifi-host-cmn")
