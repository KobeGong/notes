# cc命令解说

多数UNIX平台都通过CC调用它们的C编译程序.除标准和CC以外,LINUX和FREEBSD还支持gcc. 基本的编译命令有以下几种:

1. -c 编译产生对象文件(*.obj)而不链接成可执行文件,当编译几个独立的模块,而待以后由链接程序把它们链接在一起时,就可以使用这个选项,如:
    <pre><code>
    $cc -c hello.c
    $cc hello.o
    </code></pre>
2. -o 允许用户指定输出文件名,如
    <pre><code>$cc hello.c -o hello.o</code></pre>
    or
    <pre><code>$cc hello.c -o hello</code></pre>
3. -g 指明编译程序在编译的输出中应产生调试信息.这个调试信息使源代码和变量名引用在调试程序中或者当程序异常退出后在分析core文件时可被使用.    
4. -D   允许从编译程序命令行定义宏符号
         一共有两种情况:一种是用-DMACRO,相当于在程序中使用#define MACRO,另一种是用-DMACRO=A,相当于程序中的#define MACRO A.如对下面这代码:           #ifdefine DEBUG                     printf("debug message/n");          #endif        编译时可加上-DDEBUG参数,执行程序则打印出编译信息    
5. -I   可指定查找include文件的其他位置.例如,如果有些include文件位于比较特殊的地方,比如/usr/local/include,就可以增加此选项如下:

	```
	$cc -c -I/usr/local/include -I/opt/include hello.c 
	```

	此时目录搜索会按给出的次序进行.   
6. -E 这个选项是相对标准的,它允许修改命令行以使编译程序把预先处理的C文件发到标准输出,而不实际编译代码.在查看C预处理伪指令和C宏时,这是很有用的.可能的编译输出可重新定向到一个文件,然后用编辑程序来分析:

	```
	$cc -c -E hello.c >cpp.out
	```

	此命令使include文件和程序被预先处理并重定向到文件cpp.out.以后可以用编辑程序或者分页命令分析这个文件,并确定最终的C语言代码看起来如何.   
7. -o 优化选项,这个选项不是标准的
	* -O和 -O1指定1级优化
	* -O2 指定2级优化
	* -O3 指定3级优化
	* -O0指定不优化

	```
	$cc -c O3 -O0 hello.c
	```

	当出现多个优化时,以最后一个为准!!    
8. -Wall 以最高级别使用GNU编译程序,专门用于显示警告用!!

	```
	$gcc -Wall hello.c
	```

9. -L 指定连接库的搜索目录, -l(小写L)指定连接库的名字

	```
	$gcc main.o -L/usr/lib -lqt -o hello
	```

	上面的命令把目标文件main.o与库qt相连接,连接时会到/usr/lib查找这个库文件.也就是说-L与-l一般要成对出现.