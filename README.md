github: https://github.com/CarlZhongZ/cocos_editor

qq技术交流群:474161305

详细文档: [点击查看](https://note.youdao.com/ynoteshare1/index.html?id=e89ed0967396ff847c4d745d1846f374&type=note#/)

# 简单介绍
基于 cocos2dx 最新版的自研编辑器。经历数年的使用与迭代.

# 主要功能:
> 1.UI编辑.

> 2.基于 cocos action 机制的 动画编辑.

# 特色
> 1.编辑器编辑 UI 十分方便, 增加了很多提升开发游戏效率的节点以及属性.

> 2.UI组件化, 可以被其他UI复用.

> 3.UI节点类型多样, 扩展类型方便.

> 4.动画编辑器支持所有 cocos2dx 的 action 以及提供的方便的扩展机制. 能够及时地预览编辑出来的效果.

> 6.支持多国语言版本的开发.

> 7.强大的分辨率适配机制. 适配不同手机的分辨率不需要写代码. (并且分辨率适配机制也是可以扩展的)

> 8.编辑器能够自己迭代开发自己.


# 简单使用
## 如何运行
> 方法一：将engine目录下的 exe 和 dll 全都复制到bin目录下双击exe即可运行

> 方法二：在engine 目录下运行命令行 Engine317.exe -console -workdir C:\Users\Administrator\Desktop\work\my_github\cc_editor\bin/   (bin为工作目录)

> 第一次运行会弹出设置面板让你设置资源目录, 将目录设置成 bin 目录下的 res目录即可(或者设置成开发项目的 res目录, 可以理解编辑器的res 为编辑器项目),设置好后点确定即可。
<img src="https://raw.githubusercontent.com/CarlZhongZ/cocos_editor/master/docs/first_setting.png" alt="alt text" title="Title" />

## UI编辑器
<img src="https://raw.githubusercontent.com/CarlZhongZ/cocos_editor/master/docs/UI_editor.png" alt="alt text" title="Title" />

## 动画编辑
<img src="https://raw.githubusercontent.com/CarlZhongZ/cocos_editor/master/docs/action_ani_editor.png" alt="alt text" title="Title" />

> 使用教程可以参照 docs/编辑器.xmind 里面的操作说明, 至于其他细节的教程, 以后有时间会一一补齐

> 开源这套编辑器的目的是为了不断完善这个编辑器以及通过技术交流学习提升, 共勉

# 简单开发流程使用介绍

- 初次打开编辑器，点击新建项目，指定一个目录，会自动生成 一个项目目录, 目录下带有脚本(src 目录)框架代码, 以及 资源(res 目录) 资源最少的目录结构文件
<img src="https://raw.githubusercontent.com/CarlZhongZ/cocos_editor/master/docs/new_project/图片1.png" alt="alt text" title="Title" />

<img src="https://raw.githubusercontent.com/CarlZhongZ/cocos_editor/master/docs/new_project/图片2.png" alt="alt text" title="Title" />

- 选好后点击确定

<img src="https://raw.githubusercontent.com/CarlZhongZ/cocos_editor/master/docs/new_project/图片3.png" alt="alt text" title="Title" />

- 主界面右侧是辅助用的模板列表功能，详细见编辑器说明文档的描述， 点击 tab键可以隐藏(详细操作见说明文档)

- 新建一个界面

<img src="https://raw.githubusercontent.com/CarlZhongZ/cocos_editor/master/docs/new_project/图片4.png" alt="alt text" title="Title" />

- 向界面里面加几个节点，给编辑器取名，方便代码里面定位

<img src="https://raw.githubusercontent.com/CarlZhongZ/cocos_editor/master/docs/new_project/图片5.png" alt="alt text" title="Title" />

<img src="https://raw.githubusercontent.com/CarlZhongZ/cocos_editor/master/docs/new_project/图片6.png" alt="alt text" title="Title" />

- 按ctrl + s 保存文档名为 test_panel, 然后点击生成代码取名 dlg_test_panel

<img src="https://raw.githubusercontent.com/CarlZhongZ/cocos_editor/master/docs/new_project/图片7.png" alt="alt text" title="Title" />

<img src="https://raw.githubusercontent.com/CarlZhongZ/cocos_editor/master/docs/new_project/图片8.png" alt="alt text" title="Title" />

<img src="https://raw.githubusercontent.com/CarlZhongZ/cocos_editor/master/docs/new_project/图片9.png" alt="alt text" title="Title" />

在logic_init.lua 中填写程序初始化代码:
```
g_panel_mgr.show_in_new_scene('dlg_test_panel')
```
在 dlg_test_panel.lua 中填写逻辑代码:
```
function Panel:init_panel(...)
    self.testBtn.OnClick = function()
        message('btn on clicked')
    end

    self.testCheckBtn.OnChecked = function(bCheck, index)
        message(string.format('testCheckBtn.OnChecked:%s %s', tostring(bCheck), tostring(index)))
    end
end

```
<img src="https://raw.githubusercontent.com/CarlZhongZ/cocos_editor/master/docs/new_project/图片10.png" alt="alt text" title="Title" />

代码写完后就点击运行就可以跑写出来的程序了:
<img src="https://raw.githubusercontent.com/CarlZhongZ/cocos_editor/master/docs/new_project/图片11.png" alt="alt text" title="Title" />
