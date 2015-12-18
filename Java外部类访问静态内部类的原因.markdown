# Java外部类访问静态内部类的原因

标签（空格分隔）： Java

---

在Java中，我们可以在一个定义一个静态内部类，静态内部类和非静态内部类不同，它不会持有外部类的引用。我们将一个类定义成静态内部类和普通类的区别不大，个人认为有两个不同。
1. class文件名称不同。静态内部类的class文件名由其类名和其外部类名共同决定，具体是外部类的全名$内部类名.class
2. 静态内部类所属的外部类可以访问静态内部类的私有成员和私有方法。
3. 定义的位置不同。内部类嘛，是定义在某个类的内部。（废话）

既然和普通类的区别不大，普通类的私有方法，我们在外部是无法访问的，但是为什么静态内部类的外部类可以访问其私有成员和私有方法？

下面是一段简单的静态内部类的示例。
```
public class TestMain {
    public int    mX = 0;
   
    public static void main(String[] args) {
        Child child = new Child();
        child.name = "kobe";
        System.out.println(child.name);
        return;
    }

    public TestMain(){
    }
    public void test(){
        return;
    }

    public static class Child{
        private String name;

        public Child(){
            this.name = name;
        }
    }
}
```
在这段代码中，定义一个TestMain类，它有一个静态内部类Child，在main函数中创建了一个child的对象，并直接修改child的私有成员name的值为"kobe"，编译执行，一切ok。

下面通过javap命令，查看TestMain的class文件，看看它的字节码是什么样子的。
```
> javap -v com/test/TestMain.class
Classfile /Users/baidu/java_code/javavmtest/JavaCode/src/com/test/TestMain.class
  Last modified 2015-12-18; size 767 bytes
  MD5 checksum c923ce6a5bb70b704b1c5b0cc67e99d7
  Compiled from "TestMain.java"
public class com.test.TestMain
  SourceFile: "TestMain.java"
  InnerClasses:
       public static #12= #1 of #10; //Child=class com/test/TestMain$Child of class com/test/TestMain
  minor version: 0
  major version: 51
  flags: ACC_PUBLIC, ACC_SUPER
Constant pool:
   #1 = Class              #25            //  com/test/TestMain$Child
   #2 = Methodref          #1.#26         //  com/test/TestMain$Child."<init>":()V
   #3 = String             #27            //  kobe
   #4 = Methodref          #1.#28         //  com/test/TestMain$Child.access$002:(Lcom/test/TestMain$Child;Ljava/lang/String;)Ljava/lang/String;
   #5 = Fieldref           #29.#30        //  java/lang/System.out:Ljava/io/PrintStream;
   #6 = Methodref          #1.#31         //  com/test/TestMain$Child.access$000:(Lcom/test/TestMain$Child;)Ljava/lang/String;
   #7 = Methodref          #32.#33        //  java/io/PrintStream.println:(Ljava/lang/String;)V
   #8 = Methodref          #11.#26        //  java/lang/Object."<init>":()V
   #9 = Fieldref           #10.#34        //  com/test/TestMain.mX:I
  #10 = Class              #35            //  com/test/TestMain
  #11 = Class              #36            //  java/lang/Object
  #12 = Utf8               Child
  #13 = Utf8               InnerClasses
  #14 = Utf8               mX
  #15 = Utf8               I
  #16 = Utf8               main
  #17 = Utf8               ([Ljava/lang/String;)V
  #18 = Utf8               Code
  #19 = Utf8               LineNumberTable
  #20 = Utf8               <init>
  #21 = Utf8               ()V
  #22 = Utf8               test
  #23 = Utf8               SourceFile
  #24 = Utf8               TestMain.java
  #25 = Utf8               com/test/TestMain$Child
  #26 = NameAndType        #20:#21        //  "<init>":()V
  #27 = Utf8               kobe
  #28 = NameAndType        #37:#38        //  access$002:(Lcom/test/TestMain$Child;Ljava/lang/String;)Ljava/lang/String;
  #29 = Class              #39            //  java/lang/System
  #30 = NameAndType        #40:#41        //  out:Ljava/io/PrintStream;
  #31 = NameAndType        #42:#43        //  access$000:(Lcom/test/TestMain$Child;)Ljava/lang/String;
  #32 = Class              #44            //  java/io/PrintStream
  #33 = NameAndType        #45:#46        //  println:(Ljava/lang/String;)V
  #34 = NameAndType        #14:#15        //  mX:I
  #35 = Utf8               com/test/TestMain
  #36 = Utf8               java/lang/Object
  #37 = Utf8               access$002
  #38 = Utf8               (Lcom/test/TestMain$Child;Ljava/lang/String;)Ljava/lang/String;
  #39 = Utf8               java/lang/System
  #40 = Utf8               out
  #41 = Utf8               Ljava/io/PrintStream;
  #42 = Utf8               access$000
  #43 = Utf8               (Lcom/test/TestMain$Child;)Ljava/lang/String;
  #44 = Utf8               java/io/PrintStream
  #45 = Utf8               println
  #46 = Utf8               (Ljava/lang/String;)V
{
  public int mX;
    flags: ACC_PUBLIC

  public static void main(java.lang.String[]);
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
      stack=2, locals=2, args_size=1
         0: new           #1                  // class com/test/TestMain$Child
         3: dup
         4: invokespecial #2                  // Method com/test/TestMain$Child."<init>":()V
         7: astore_1
         8: aload_1
         9: ldc           #3                  // String kobe
        11: invokestatic  #4                  // Method com/test/TestMain$Child.access$002:(Lcom/test/TestMain$Child;Ljava/lang/String;)Ljava/lang/String;
        14: pop
        15: getstatic     #5                  // Field java/lang/System.out:Ljava/io/PrintStream;
        18: aload_1
        19: invokestatic  #6                  // Method com/test/TestMain$Child.access$000:(Lcom/test/TestMain$Child;)Ljava/lang/String;
        22: invokevirtual #7                  // Method java/io/PrintStream.println:(Ljava/lang/String;)V
        25: return
      LineNumberTable:
        line 7: 0
        line 8: 8
        line 9: 15
        line 10: 25

  public com.test.TestMain();
    flags: ACC_PUBLIC
    Code:
      stack=2, locals=1, args_size=1
         0: aload_0
         1: invokespecial #8                  // Method java/lang/Object."<init>":()V
         4: aload_0
         5: iconst_0
         6: putfield      #9                  // Field mX:I
         9: return
      LineNumberTable:
        line 13: 0
        line 4: 4
        line 14: 9

  public void test();
    flags: ACC_PUBLIC
    Code:
      stack=0, locals=1, args_size=1
         0: return
      LineNumberTable:
        line 16: 0
}
```
第64行，开始执行main函数，从68行到70行是创建child对象，73行到74行将"kobe"赋值给了child的name成员，注意74行通过调用Child的静态方法access\$002完成给child.name赋值。access\$002并不是我们源码中写的，很明显这是Java编译器生成的代码。
下面是Child的字节码。
```
> javap -v com.test.TestMain\$Child
Classfile /Users/baidu/java_code/javavmtest/JavaCode/src/com/test/TestMain$Child.class
  Last modified 2015-12-18; size 557 bytes
  MD5 checksum 5f94b1089e491b12816272c9bc88bf32
  Compiled from "TestMain.java"
public class com.test.TestMain$Child
  SourceFile: "TestMain.java"
  InnerClasses:
       public static #12= #3 of #21; //Child=class com/test/TestMain$Child of class com/test/TestMain
  minor version: 0
  major version: 51
  flags: ACC_PUBLIC, ACC_SUPER
Constant pool:
   #1 = Fieldref           #3.#19         //  com/test/TestMain$Child.name:Ljava/lang/String;
   #2 = Methodref          #4.#20         //  java/lang/Object."<init>":()V
   #3 = Class              #22            //  com/test/TestMain$Child
   #4 = Class              #23            //  java/lang/Object
   #5 = Utf8               name
   #6 = Utf8               Ljava/lang/String;
   #7 = Utf8               <init>
   #8 = Utf8               ()V
   #9 = Utf8               Code
  #10 = Utf8               LineNumberTable
  #11 = Utf8               access$002
  #12 = Utf8               Child
  #13 = Utf8               InnerClasses
  #14 = Utf8               (Lcom/test/TestMain$Child;Ljava/lang/String;)Ljava/lang/String;
  #15 = Utf8               access$000
  #16 = Utf8               (Lcom/test/TestMain$Child;)Ljava/lang/String;
  #17 = Utf8               SourceFile
  #18 = Utf8               TestMain.java
  #19 = NameAndType        #5:#6          //  name:Ljava/lang/String;
  #20 = NameAndType        #7:#8          //  "<init>":()V
  #21 = Class              #24            //  com/test/TestMain
  #22 = Utf8               com/test/TestMain$Child
  #23 = Utf8               java/lang/Object
  #24 = Utf8               com/test/TestMain
{
  public com.test.TestMain$Child();
    flags: ACC_PUBLIC
    Code:
      stack=2, locals=1, args_size=1
         0: aload_0
         1: invokespecial #2                  // Method java/lang/Object."<init>":()V
         4: aload_0
         5: aload_0
         6: getfield      #1                  // Field name:Ljava/lang/String;
         9: putfield      #1                  // Field name:Ljava/lang/String;
        12: return
      LineNumberTable:
        line 22: 0
        line 23: 4
        line 24: 12

  static java.lang.String access$002(com.test.TestMain$Child, java.lang.String);
    flags: ACC_STATIC, ACC_SYNTHETIC
    Code:
      stack=3, locals=2, args_size=2
         0: aload_0
         1: aload_1
         2: dup_x1
         3: putfield      #1                  // Field name:Ljava/lang/String;
         6: areturn
      LineNumberTable:
        line 19: 0

  static java.lang.String access$000(com.test.TestMain$Child);
    flags: ACC_STATIC, ACC_SYNTHETIC
    Code:
      stack=1, locals=1, args_size=1
         0: aload_0
         1: getfield      #1                  // Field name:Ljava/lang/String;
         4: areturn
      LineNumberTable:
        line 19: 0
}
```
很明显，编译器替我们生成了两个静态方法access$002和access$000，这两个方法很简单，access$002是修改name成员值的，access$000是返回name值得。flags：ACC_SYNTHETIC 说明由编译器产生,不存在于源代码中。
