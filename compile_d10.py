"""用 Delphi 10 (Studio 17.0) + IDE 的真实库搜索路径编译 dpr。

背景：
  本机装了 Studio 17.0(Delphi 10) 和 21.0(Delphi 10.4)。
  Win32\\Release 下那些第三方单元的 DCU 是 17.0 编的，只有 17.0 的 dcc32 加载得了；
  用 21.0 编会报 F2613 Unit not found。

  第三方库(Raize/CnSkin/CPort/EhLib/FastReport 等)的搜索路径**不在 dproj 里**，
  而是 IDE 的全局库搜索选项（Options > Library），编译日志里会完整展开成
  -U/-I/-R/-O 四份。本脚本把这些路径固化到 IDE_PATHS，
  和 IDE 日志里那份保持一致；以后 IDE 里改了库路径，记得同步这里。

用法:
  python compile_d10.py                # 编译 Test_Project_Pro.dpr
  python compile_d10.py - --passthru   # 原样打印 dcc32 命令行（调试用）
"""
import os
import subprocess
import sys

DCC32 = r"D:\Program Files (x86)\Embarcadero\Studio\17.0\bin\dcc32.exe"
STUDIO = r"D:\Program Files (x86)\Embarcadero\Studio\17.0"
DEFAULT_DPR = "Test_Project_Pro.dpr"

# 与 IDE 编译日志里的路径列表保持一致
IDE_PATHS = [
    r"d:\program files (x86)\embarcadero\studio\17.0\lib\Win32\release",
    r"C:\Users\hu\Documents\Embarcadero\Studio\17.0\imports",
    r"d:\program files (x86)\embarcadero\studio\17.0\imports",
    r"C:\Users\Public\Documents\Embarcadero\Studio\17.0\dcp",
    r"d:\delphi\downloads\devexpressvcl\devexpressvcl\expressbars\sources",
    r"d:\delphi\downloads\devexpressvcl\devexpressvcl\expresscommon library\sources",
    r"d:\delphi\downloads\devexpressvcl\devexpressvcl\expresscore library\sources",
    r"d:\delphi\downloads\devexpressvcl\devexpressvcl\expressdatacontroller\sources",
    r"d:\delphi\downloads\devexpressvcl\devexpressvcl\expressdbtree suite\sources",
    r"d:\delphi\downloads\devexpressvcl\devexpressvcl\expressdocking library\sources",
    r"d:\delphi\downloads\devexpressvcl\devexpressvcl\expresseditors library\sources",
    r"d:\delphi\downloads\devexpressvcl\devexpressvcl\expressexport library\sources",
    r"d:\delphi\downloads\devexpressvcl\devexpressvcl\expressflowchart\sources",
    r"d:\delphi\downloads\devexpressvcl\devexpressvcl\expressgdi+ library\sources",
    r"d:\delphi\downloads\devexpressvcl\devexpressvcl\expresslayout control\sources",
    r"d:\delphi\downloads\devexpressvcl\devexpressvcl\expresslibrary\sources",
    r"d:\delphi\downloads\devexpressvcl\devexpressvcl\expressmemdata\sources",
    r"d:\delphi\downloads\devexpressvcl\devexpressvcl\expressnavbar\sources",
    r"d:\delphi\downloads\devexpressvcl\devexpressvcl\expressorgchart\sources",
    r"d:\delphi\downloads\devexpressvcl\devexpressvcl\expresspagecontrol\sources",
    r"d:\delphi\downloads\devexpressvcl\devexpressvcl\expresspivotgrid\sources",
    r"d:\delphi\downloads\devexpressvcl\devexpressvcl\expressprinting system\sources",
    r"d:\delphi\downloads\devexpressvcl\devexpressvcl\expressquantumgrid\sources",
    r"d:\delphi\downloads\devexpressvcl\devexpressvcl\expressquantumtreelist\sources",
    r"d:\delphi\downloads\devexpressvcl\devexpressvcl\expressscheduler\sources",
    r"d:\delphi\downloads\devexpressvcl\devexpressvcl\expressskins library\sources",
    r"d:\delphi\downloads\devexpressvcl\devexpressvcl\expressspellchecker\sources",
    r"d:\delphi\downloads\devexpressvcl\devexpressvcl\expressspreadsheet\sources",
    r"d:\delphi\downloads\devexpressvcl\devexpressvcl\expressverticalgrid\sources",
    r"d:\delphi\downloads\devexpressvcl\devexpressvcl\xp theme manager\sources",
    r"d:\delphi\downloads\devexpressvcl\devexpressvcl\expresstile control\sources",
    r"d:\delphi\downloads\devexpressvcl\devexpressvcl\expresswizard control\sources",
    r"d:\delphi\downloads\devexpressvcl\devexpressvcl\expressgauge control\sources",
    r"d:\delphi\downloads\devexpressvcl\devexpressvcl\expressmap control\sources",
    r"d:\delphi\downloads\devexpressvcl\devexpressvcl\expressspreadsheet (deprecated)\sources",
    r"d:\delphi\downloads\devexpressvcl\devexpressvcl\expressrichedit control\sources",
    r"d:\delphi\downloads\devexpressvcl\devexpressvcl\expressofficecore library\sources",
    r"d:\delphi\downloads\devexpressvcl\devexpressvcl\expresspdfviewer\sources",
    r"d:\Program Files (x86)\Embarcadero\Studio\17.0\Components\EhLib\Lib\Win32\Release",
    r"D:\Delphi\DownLoads\TNTUniCtrlsWithExceptions_2.3.0\Source",
    r"D:\Delphi\DownLoads\TNTUniCtrlsWithExceptions_2.3.0\Design",
    r"D:\Delphi\DownLoads\TNTUniCtrlsWithExceptions_2.3.0\Delphi\bds4",
    r"D:\Delphi\DownLoads\Konopka+Controls+6.2.3+for+Delphi+DX10.3+Rio+-+Offical\Source",
    r"D:\Delphi\DownLoads\RxLib 2.75 for Delphi D5-DX10.4 Sydney\units",
    r"D:\Delphi\DownLoads\cnvcl_20230405\cnvcl\Source",
    r"D:\Delphi\DownLoads\cnvcl_20230405\cnvcl\Source\Common",
    r"D:\Delphi\DownLoads\cnvcl_20230405\cnvcl\Source\Crypto",
    r"D:\Delphi\DownLoads\cnvcl_20230405\cnvcl\Source\DbReport",
    r"D:\Delphi\DownLoads\cnvcl_20230405\cnvcl\Source\Graphics",
    r"D:\Delphi\DownLoads\cnvcl_20230405\cnvcl\Source\MultiLang",
    r"D:\Delphi\DownLoads\cnvcl_20230405\cnvcl\Source\NetComm",
    r"D:\Delphi\DownLoads\cnvcl_20230405\cnvcl\Source\NonVisual",
    r"D:\Delphi\DownLoads\cnvcl_20230405\cnvcl\Source\ObjRep",
    r"D:\Delphi\DownLoads\cnvcl_20230405\cnvcl\Source\Skin",
    r"D:\Delphi\DownLoads\cnvcl_20230405\cnvcl\Source\ThirdParty",
    r"D:\Delphi\DownLoads\LMD_VCL_Complete_2016.5_D6-RX10.2_FULL_SOURCE_Downloadly.ir\LMD VCL Complete 2016.5 D6~RX10.2 FULL SOURCE\source",
    r"D:\Delphi\DownLoads\JVCL349CompleteJCL27-Build5676\jcl\lib\d23\win32",
    r"D:\Delphi\DownLoads\JVCL349CompleteJCL27-Build5676\jcl\source\include",
    r"D:\Delphi\DownLoads\JVCL349CompleteJCL27-Build5676\jvcl\lib\D23\win32",
    r"D:\Delphi\DownLoads\JVCL349CompleteJCL27-Build5676\jvcl\common",
    r"D:\Delphi\DownLoads\JVCL349CompleteJCL27-Build5676\jvcl\Resources",
    r"D:\Delphi\DownLoads\TMS+VCL+UI+Pack+10.5.0.2+for+Delphi+7-XE10.4+Full+Source",
    r"D:\Delphi\DownLoads\TMS+VCL+UI+Pack+10.5.0.2+for+Delphi+7-XE10.4+Full+Source\xlsAdapter",
    r"d:\Program Files\Barcode2D\bds_10",
    r"d:\Program Files\Barcode2D\bds_10\win64",
    r"D:\Delphi\DownLoads\Comport4.14\Source",
    r"D:\Delphi\DownLoads\VCLSkin+5.8+Full+Source+D5-XE6,DX10.2,DX10.3\Source",
    r"D:\Delphi\DownLoads\VCLSkin\VCLSkin560\source",
    r"d:\Program Files (x86)\nrComm Lib\Delphi23\Win32",
    r"d:\Program Files (x86)\nrComm Lib\Res",
    r"d:\Program Files (x86)\nrComm Lib\Source",
    r"d:\Program Files (x86)\nrComm Lib\Delphi23",
    r"D:\Delphi\DownLoads\ComPort Library 2015 Full Source XE10_2\ComPort Library 2015Lib",
    r"D:\Delphi\DownLoads\EhLib.VCL+10.1+for+D7-DelphiXE+10.4\Common",
    r"D:\Delphi\DownLoads\BusinessSkinForm VCL 12.10 D6~10.4 Sydney",
    r"D:\Program Files (x86)\FastReport 6 VCL Enterprise\Source\ADO",
    r"D:\Program Files (x86)\FastReport 6 VCL Enterprise\Source\BDE",
    r"D:\Program Files (x86)\FastReport 6 VCL Enterprise\Source\ClientServer",
    r"D:\Program Files (x86)\FastReport 6 VCL Enterprise\Source\DBX",
    r"D:\Program Files (x86)\FastReport 6 VCL Enterprise\Source\ExportPack",
    r"D:\Program Files (x86)\FastReport 6 VCL Enterprise\Source\FIB",
    r"D:\Program Files (x86)\FastReport 6 VCL Enterprise\Source\FireDAC",
    r"D:\Program Files (x86)\FastReport 6 VCL Enterprise\Source\lazchart",
    r"D:\Program Files (x86)\FastReport 6 VCL Enterprise\Source\lazdbf",
    r"D:\Program Files (x86)\FastReport 6 VCL Enterprise\Source\sqlite",
    r"D:\Program Files (x86)\FastReport 6 VCL Enterprise\LibD23",
    r"D:\Program Files (x86)\FastReport 6 VCL Enterprise\LibD23x64",
    r"D:\Delphi\DownLoads\Nevrona Rave Reports V.11.0.14 D7-XE10.4",
    r"D:\Delphi\DownLoads\Enlib.v.3.09.D7-XE10.1.Src.Exirbox\lib",
    r"D:\Delphi\DownLoads\Enlib.v.3.09.D7-XE10.1.Src.Exirbox\Source",
    r"D:\Delphi\DownLoads\FlyTreeViewPro.Suite for D10.3\Source",
    r"D:\Delphi\DownLoads\ImgBtn\ImgBtn1支持png三态按钮V2.0版\控件",
    r"D:\Delphi\DownLoads\luke_LssCalendar2\LssCalendar2",
    r"D:\Delphi\DownLoads\CustomButton\CustomButton",
    r"C:\undelphix_1_20_0\Source\Dcu230",
    r"C:\undelphix_1_20_0\Source",
    r"D:\Delphi\DownLoads\DevExpressVCL\DevExpressVCL",
    r"D:\Delphi\DownLoads\DevExpressVCL\DevExpressVCL\ExpressBars\Packages",
    r"D:\Delphi\DownLoads\DevExpressVCL\DevExpressVCL\ExpressBars\Sources",
    r"D:\Delphi\DownLoads\DevExpressVCL\DevExpressVCL\ExpressCommon Library\Packages",
    r"D:\Delphi\DownLoads\DevExpressVCL\DevExpressVCL\ExpressCommon Library\Sources",
    r"D:\Delphi\DownLoads\DevExpressVCL\DevExpressVCL\ExpressCore Library\Packages",
    r"D:\Delphi\DownLoads\DevExpressVCL\DevExpressVCL\ExpressCore Library\Sources",
    r"D:\Delphi\DownLoads\DevExpressVCL\DevExpressVCL\ExpressDataController\Packages",
    r"D:\Delphi\DownLoads\DevExpressVCL\DevExpressVCL\ExpressDataController\Sources",
    r"D:\Delphi\DownLoads\DevExpressVCL\DevExpressVCL\ExpressDBTree Suite\Packages",
    r"D:\Delphi\DownLoads\DevExpressVCL\DevExpressVCL\ExpressDBTree Suite\Sources",
    r"D:\Delphi\DownLoads\DevExpressVCL\DevExpressVCL\ExpressDocking Library\Packages",
    r"D:\Delphi\DownLoads\DevExpressVCL\DevExpressVCL\ExpressDocking Library\Sources",
    r"D:\Delphi\DownLoads\DevExpressVCL\DevExpressVCL\ExpressEditors Library\Packages",
    r"D:\Delphi\DownLoads\DevExpressVCL\DevExpressVCL\ExpressEditors Library\Sources",
    r"D:\Delphi\DownLoads\DevExpressVCL\DevExpressVCL\ExpressExport Library\Packages",
    r"D:\Delphi\DownLoads\DevExpressVCL\DevExpressVCL\ExpressExport Library\Sources",
    r"D:\Delphi\DownLoads\DevExpressVCL\DevExpressVCL\ExpressFlowChart\Packages",
    r"D:\Delphi\DownLoads\DevExpressVCL\DevExpressVCL\ExpressFlowChart\Sources",
    r"D:\Delphi\DownLoads\DevExpressVCL\DevExpressVCL\ExpressGauge Control\Packages",
    r"D:\Delphi\DownLoads\DevExpressVCL\DevExpressVCL\ExpressGauge Control\Sources",
    r"D:\Delphi\DownLoads\DevExpressVCL\DevExpressVCL\ExpressGDI+ Library\Packages",
    r"D:\Delphi\DownLoads\DevExpressVCL\DevExpressVCL\ExpressGDI+ Library\Sources",
    r"D:\Delphi\DownLoads\DevExpressVCL\DevExpressVCL\ExpressLayout Control\Packages",
    r"D:\Delphi\DownLoads\DevExpressVCL\DevExpressVCL\ExpressLayout Control\Sources",
    r"D:\Delphi\DownLoads\DevExpressVCL\DevExpressVCL\ExpressLibrary\Packages",
    r"D:\Delphi\DownLoads\DevExpressVCL\DevExpressVCL\ExpressLibrary\Sources",
    r"D:\Delphi\DownLoads\DevExpressVCL\DevExpressVCL\ExpressMap Control\Packages",
    r"D:\Delphi\DownLoads\DevExpressVCL\DevExpressVCL\ExpressMap Control\Sources",
    r"D:\Delphi\DownLoads\DevExpressVCL\DevExpressVCL\ExpressMemData\Packages",
    r"D:\Delphi\DownLoads\DevExpressVCL\DevExpressVCL\ExpressMemData\Sources",
    r"D:\Delphi\DownLoads\DevExpressVCL\DevExpressVCL\ExpressNavBar\Packages",
    r"D:\Delphi\DownLoads\DevExpressVCL\DevExpressVCL\ExpressNavBar\Sources",
    r"D:\Delphi\DownLoads\DevExpressVCL\DevExpressVCL\ExpressOrgChart\Packages",
    r"D:\Delphi\DownLoads\DevExpressVCL\DevExpressVCL\ExpressOrgChart\Sources",
    r"D:\Delphi\DownLoads\DevExpressVCL\DevExpressVCL\ExpressPageControl\Packages",
    r"D:\Delphi\DownLoads\DevExpressVCL\DevExpressVCL\ExpressPageControl\Sources",
    r"D:\Delphi\DownLoads\DevExpressVCL\DevExpressVCL\ExpressPivotGrid\Packages",
    r"D:\Delphi\DownLoads\DevExpressVCL\DevExpressVCL\ExpressPivotGrid\Sources",
    r"D:\Delphi\DownLoads\DevExpressVCL\DevExpressVCL\ExpressPrinting System\Packages",
    r"D:\Delphi\DownLoads\DevExpressVCL\DevExpressVCL\ExpressPrinting System\Sources",
    r"D:\Delphi\DownLoads\DevExpressVCL\DevExpressVCL\ExpressQuantumGrid\Packages",
    r"D:\Delphi\DownLoads\DevExpressVCL\DevExpressVCL\ExpressQuantumGrid\Sources",
    r"D:\Delphi\DownLoads\DevExpressVCL\DevExpressVCL\ExpressQuantumTreeList\Packages",
    r"D:\Delphi\DownLoads\DevExpressVCL\DevExpressVCL\ExpressQuantumTreeList\Sources",
    r"D:\Delphi\DownLoads\DevExpressVCL\DevExpressVCL\ExpressRichEdit Control\Packages",
    r"D:\Delphi\DownLoads\DevExpressVCL\DevExpressVCL\ExpressRichEdit Control\Sources",
    r"D:\Delphi\DownLoads\DevExpressVCL\DevExpressVCL\ExpressScheduler\Packages",
    r"D:\Delphi\DownLoads\DevExpressVCL\DevExpressVCL\ExpressScheduler\Sources",
    r"D:\Delphi\DownLoads\DevExpressVCL\DevExpressVCL\ExpressSkins Library\Packages",
    r"D:\Delphi\DownLoads\DevExpressVCL\DevExpressVCL\ExpressSkins Library\Sources",
    r"D:\Delphi\DownLoads\DevExpressVCL\DevExpressVCL\ExpressSpellChecker\Packages",
    r"D:\Delphi\DownLoads\DevExpressVCL\DevExpressVCL\ExpressSpellChecker\Sources",
    r"D:\Delphi\DownLoads\DevExpressVCL\DevExpressVCL\ExpressSpreadSheet (deprecated)\Packages",
    r"D:\Delphi\DownLoads\DevExpressVCL\DevExpressVCL\ExpressSpreadSheet (deprecated)\Sources",
    r"D:\Delphi\DownLoads\DevExpressVCL\DevExpressVCL\ExpressSpreadSheet\Packages",
    r"D:\Delphi\DownLoads\DevExpressVCL\DevExpressVCL\ExpressSpreadSheet\Sources",
    r"D:\Delphi\DownLoads\DevExpressVCL\DevExpressVCL\ExpressTile Control\Packages",
    r"D:\Delphi\DownLoads\DevExpressVCL\DevExpressVCL\ExpressTile Control\Sources",
    r"D:\Delphi\DownLoads\DevExpressVCL\DevExpressVCL\ExpressVerticalGrid\Packages",
    r"D:\Delphi\DownLoads\DevExpressVCL\DevExpressVCL\ExpressVerticalGrid\Sources",
    r"D:\Delphi\DownLoads\DevExpressVCL\DevExpressVCL\ExpressWizard Control\Packages",
    r"D:\Delphi\DownLoads\DevExpressVCL\DevExpressVCL\ExpressWizard Control\Sources",
    r"D:\Delphi\DownLoads\DevExpressVCL\DevExpressVCL\Library\RS23\Win32\DCU",
    r"D:\Delphi\DownLoads\DevExpressVCL\DevExpressVCL\Library\RS23\Win64\DCU",
    r"D:\Delphi\DownLoads\DevExpressVCL\DevExpressVCL\XP Theme Manager\Packages",
    r"D:\Delphi\DownLoads\DevExpressVCL\DevExpressVCL\XP Theme Manager\Sources",
    r"D:\Delphi\DownLoads\MitovLabs VCL 7.8.2.0 Full Source for Delphi 10.1 Berlin_2\Source",
    r"D:\Delphi\DownLoads\MitovLabs VCL 7.8.2.0 Full Source for Delphi 10.1 Berlin_2\Source\10.1",
    r"D:\Delphi\DownLoads\MitovLabs VCL 7.8.2.0 Full Source for Delphi 10.1 Berlin_2\Source\10.1\Win32",
    r"d:\delphi\downloads\mitovlabs vcl 7.8.2.0 full source for delphi 10.1 berlin_2\source\10.1\win32\debug",
    r"D:\Delphi\DownLoads\MitovLabs VCL 7.8.2.0 Full Source for Delphi 10.1 Berlin_2\Source\10.1\Win64",
    r"D:\Delphi\DownLoads\MitovLabs VCL 7.8.2.0 Full Source for Delphi 10.1 Berlin_2\Source\IPPLib",
    r"D:\Delphi\DownLoads\MitovLabs VCL 7.8.2.0 Full Source for Delphi 10.1 Berlin_2\Source\RX\Win32",
    r"D:\Delphi\DownLoads\AlphaControls14.23_20190502_Full_Source\AlphaControls14.23(20190502)",
    r"D:\Delphi\Mitov\LabPacks",
    r"D:\Delphi\DownLoads\icsv92\Source",
    r"D:\Delphi\DownLoads\icsv92\demos-delphi-vcl",
    r"D:\Delphi\DownLoads\skia4delphi-main\Source",
    r"D:\Delphi\DownLoads\skia4delphi-main\Source\VCL",
    r"D:\Delphi\DownLoads\skia4delphi-main\Source\VCL\Designtime",
    r"D:\Delphi\DownLoads\skia4delphi-main\Source\FMX",
    r"D:\Delphi\DownLoads\skia4delphi-main\Source\FMX\Designtime",
    r"D:\Delphi\DownLoads\skia4delphi-main\Library\RAD Studio 10.0 Seattle\Win32\Debug\Bpl",
    r"D:\Delphi\DownLoads\skia4delphi-main\Packages\Seattle",
    r"D:\Delphi\DownLoads\RxLib 2.75 for Delphi D5-DX10.4 Sydney\units\Resources",
]


def write_cfg(projdir):
    """把库搜索路径写进工程目录的 dcc32.cfg。

    dcc32 会自动读取当前目录下的 dcc32.cfg，这样命令行只需传 dpr 路径。
    必须这么做的原因：第三方库路径有 200+ 条，展开成 -U/-I/-O/-R 四份后
    命令行长度超过 Windows 的 32767 字符上限，直接报 WinError 206。
    """
    # Test_Project_Pro.dpr 里写的是 fail_pro in '..\fail_pro.pas'（相对 dpr 目录向上找），
    # 而文件实际就在工程目录。IDE 能编过是因为库搜索路径里带了上级目录，
    # 这里显式把父目录也加进搜索路径，跟 IDE 的行为保持一致。
    joined = ";".join(IDE_PATHS + [projdir, os.path.dirname(projdir)])
    cfg = os.path.join(projdir, "dcc32.cfg")
    with open(cfg, "w", encoding="gbk", errors="replace") as f:
        f.write('-$D0\n')          # 忽略项目里的 $D 指令
        f.write('-$L-\n')
        f.write('-$Y-\n')
        f.write("-AGenerics.Collections=System.Generics.Collections;"
                "Generics.Defaults=System.Generics.Defaults;WinTypes=Winapi.Windows;"
                "WinProcs=Winapi.Windows;DbiTypes=BDE;DbiProcs=BDE;DbiErrs=BDE\n")
        f.write("-DRELEASE\n")
        f.write("-M\n")
        f.write("-W-UNIT_NAME_MISMATCH\n")
        f.write('-NSWinapi;System.Win;Data.Win;Datasnap.Win;Web.Win;Soap.Win;'
                'Xml.Win;Bde;System;Xml;Data;Datasnap;Web;Soap;Vcl;'
                'Vcl.Imaging;Vcl.Touch;Vcl.Samples;Vcl.Shell\n')
        for flag in ("-U", "-I", "-R", "-O"):
            f.write('%s"%s"\n' % (flag, joined))
        f.write('-LEC:\\Users\\Public\\Documents\\Embarcadero\\Studio\\17.0\\Bpl\n')
        f.write('-LNC:\\Users\\Public\\Documents\\Embarcadero\\Studio\\17.0\\Dcp\n')
    return cfg


def build_cmd(dpr, projdir):
    """命令行只保留输出目录等短参数；长路径都在 dcc32.cfg 里。"""
    return [
        DCC32, "-B",
        "-E.\\Win32\\Release",
        "-NU.\\Win32\\Release",
        "-NO.\\Win32\\Release",
        os.path.abspath(dpr),
    ]


def main(dpr_name):
    projdir = os.path.abspath(".")
    dpr = os.path.join(projdir, dpr_name)
    cfg = write_cfg(projdir)
    cmd = build_cmd(dpr, projdir)

    if "-v" in sys.argv or "--verbose" in sys.argv:
        print(" ".join(cmd))
        return 0

    p = subprocess.run(cmd, capture_output=True, cwd=projdir)
    text = p.stdout.decode("gbk", errors="replace")
    text += p.stderr.decode("gbk", errors="replace")

    lines = text.splitlines()
    for l in lines:
        if "Error" in l or "Fatal" in l or "Warning" in l:
            print(l)

    errors = [l for l in lines if ("Error" in l or "Fatal" in l)]
    warns = [l for l in lines if "Warning" in l]
    done = any(" lines, " in l and " seconds, " in l for l in lines)

    print("-" * 60)
    print("errors = %d   warnings = %d   built = %s"
          % (len(errors), len(warns), done))
    return 0 if (not errors and done) else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1] if len(sys.argv) > 1 else DEFAULT_DPR))