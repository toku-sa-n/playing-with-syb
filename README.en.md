<!--
# sybで遊ぶ
-->

# Playing with syb

<!--
[![Deploy](https://github.com/toku-sa-n/playing-with-syb/actions/workflows/ci.yml/badge.svg)](https://github.com/toku-sa-n/playing-with-syb/actions/workflows/ci.yml)
-->

[![Deploy](https://github.com/toku-sa-n/playing-with-syb/actions/workflows/ci.yml/badge.svg)](https://github.com/toku-sa-n/playing-with-syb/actions/workflows/ci.yml)

<!--
[English version is here.](README.en.md)
-->

[日本語版はこちら．](src/Lib.lhs)

<!--
## はじめに
-->

## Introduction

<!--
この記事は，[Haskell Advent Calendar 2022](https://qiita.com/advent-calendar/2022/haskell)の20日目の記事です．
-->

This is the 20th article of [Haskell Advent Calendar 2022](https://qiita.com/advent-calendar/2022/haskell).

<!--
この記事では，Haskellライブラリの一つである[syb](https://hackage.haskell.org/package/syb-0.7.2.2)の簡単な紹介と，実際に私がプロジェクトの中で使用した例を紹介します．
-->

This article briefly introduces [syb](https://hackage.haskell.org/package/syb-0.7.2.2) which is one of Haskell libraries, and an example where I used it in a project.

<!--
## バージョン情報
-->

## Versions

<!--
| 名前                        | バージョン                    |
|-----------------------------|-------------------------------|
| Stack                       | 2.9.1                         |
| Stack resolver              | LTS 20.4                      |
| GHCやライブラリのバージョン | LTSで指定されているものを使用 |
-->

| Name                          | Version               |
|-------------------------------|-----------------------|
| Stack                         | 2.9.1                 |
| Stack resolver                | LTS 20.4              |
| Versions of GHC and libraries | Ones specified by LTS |

<!--
## `syb`とは
-->

## What is `syb`?

<!--
`syb`とはScrap Your Boilerplateの略です．[`Data`](https://hackage.haskell.org/package/base-4.16.4.0/docs/Data-Data.html#t:Data)型クラスや[`Typeable`](https://hackage.haskell.org/package/base-4.16.4.0/docs/Data-Typeable.html#t:Typeable)を利用して，データ構造に含まれている特定の型の値だけに対して操作を行ったり，特定の型の値だけを抽出するなどといったことが可能になります．
-->

`syb` stands for Scrap Your Boilerplate. It can be used to operate or extract only on values of a specific type with [`Data`](https://hackage.haskell.org/package/base-4.16.4.0/docs/Data-Data.html#t:Data) and [`Typeable`](https://hackage.haskell.org/package/base-4.16.4.0/docs/Data-Typeable.html#t:Typeable) typeclasses.

<!--
[Haskell Wiki](https://wiki.haskell.org/Research_papers/Generics)にいくつか論文が紹介されていますが，特に[Scrap Your Boilerplate: A Practical Design Pattern for Generic Programming](https://www.microsoft.com/en-us/research/wp-content/uploads/2003/01/hmap.pdf)は読みやすいのでおすすめです．
-->

[Haskell Wiki](https://wiki.haskell.org/Research_papers/Generics) lists papers related to syb. I recommend to read [Scrap Your Boilerplate: A Practical Design Pattern for Generic Programming](https://www.microsoft.com/en-us/research/wp-content/uploads/2003/01/hmap.pdf) because it is easy to read.

<!--
## コード例
-->

## Code example

<!--
以下の説明では，以下の，様々な世界に住む住民や集団の情報を一つのデータ構造に含めたものを用います．
-->

Below explanation uses the following code which includes a data structure of residents and groups in various worlds.

<!--
```haskell
{-# LANGUAGE DeriveDataTypeable  #-}
{-# LANGUAGE PatternSynonyms     #-}
{-# LANGUAGE RankNTypes          #-}
{-# LANGUAGE RecordWildCards     #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications    #-}
{-# LANGUAGE TypeFamilies        #-}

module Lib
    ( gfoldlMember
    , testMembersFromWorld
    , testMembersFromWorldWithListify
    , testListMossalcadiaMania
    , testSummonAllGroupsInKumamotoCastle
    , testAppendWorldForData
    , testAllNothing
    ) where

import           Data.Data             (Data)
import           Data.Generics.Aliases (mkT)
import           Data.Generics.Schemes (everywhere, listify)
import           Data.List             (nub)
import           Test.Hspec            (Spec, describe, it, shouldBe)
import           Type.Reflection       (eqTypeRep, pattern App, typeRep,
                                        (:~~:) (HRefl))

data World =
    World
        { worldName :: String
        , groups    :: [Group]
        }
    deriving (Data, Eq)

data Group =
    Group
        { groupName :: String
        , place     :: String
        , members   :: [Member]
        }
    deriving (Data, Eq)

data Member =
    Member
        { memberName   :: String
        , anotherName  :: String
        , age          :: Maybe Int
        , favoriteMoss :: Maybe String
        }
    deriving (Data, Eq, Show)

worlds :: [World]
worlds =
    [ World
          { worldName = "イルヴァ"
          , groups =
                [ Group
                      { groupName = "エレア"
                      , place = "ノースティリス"
                      , members =
                            [ Member
                                  { memberName = "ロミアス"
                                  , anotherName = "異形の森の使者"
                                  , age = Just 24
                                  , favoriteMoss = Nothing
                                  }
                            , Member
                                  { memberName = "ラーネイレ"
                                  , anotherName = "風を聴く者"
                                  , age = Just 22
                                  , favoriteMoss = Nothing
                                  }
                            ]
                      }
                , Group
                      { groupName = "ヴェルニースの人達"
                      , place = "ヴェルニース"
                      , members =
                            [ Member
                                  { memberName = "ウェゼル"
                                  , anotherName = "ザナンの白き鷹"
                                  , age = Just 31
                                  , favoriteMoss = Nothing
                                  }
                            , Member
                                  { memberName = "ロイター"
                                  , anotherName = "ザナンの紅の英雄"
                                  , age = Just 32
                                  , favoriteMoss = Nothing
                                  }
                            ]
                      }
                ]
          }
    , World
          { worldName = "ざくざくアクターズの世界"
          , groups =
                [ Group
                      { groupName = "ハグレ王国"
                      , place = "ハグレ王国"
                      , members =
                            [ Member
                                  { memberName = "デーリッチ"
                                  , anotherName = "ハグレ王国国王"
                                  , age = Nothing
                                  , favoriteMoss = Nothing
                                  }
                            , Member
                                  { memberName = "ローズマリー"
                                  , anotherName = "ビッグモス"
                                  , age = Nothing
                                  , favoriteMoss = Just "モスアルカディア"
                                  }
                            ]
                      }
                ]
          }
    ]
```
-->

```haskell
{-# LANGUAGE DeriveDataTypeable  #-}
{-# LANGUAGE PatternSynonyms     #-}
{-# LANGUAGE RankNTypes          #-}
{-# LANGUAGE RecordWildCards     #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications    #-}
{-# LANGUAGE TypeFamilies        #-}

module Lib
    ( gfoldlMember
    , testMembersFromWorld
    , testMembersFromWorldWithListify
    , testListMossalcadiaMania
    , testSummonAllGroupsInKumamotoCastle
    , testAppendWorldForData
    , testAllNothing
    ) where

import           Data.Data             (Data)
import           Data.Generics.Aliases (mkT)
import           Data.Generics.Schemes (everywhere, listify)
import           Data.List             (nub)
import           Test.Hspec            (Spec, describe, it, shouldBe)
import           Type.Reflection       (eqTypeRep, pattern App, typeRep,
                                        (:~~:) (HRefl))

data World =
    World
        { worldName :: String
        , groups    :: [Group]
        }
    deriving (Data, Eq)

data Group =
    Group
        { groupName :: String
        , place     :: String
        , members   :: [Member]
        }
    deriving (Data, Eq)

data Member =
    Member
        { memberName   :: String
        , anotherName  :: String
        , age          :: Maybe Int
        , favoriteMoss :: Maybe String
        }
    deriving (Data, Eq, Show)

worlds :: [World]
worlds =
    [ World
          { worldName = "Ilva"
          , groups =
                [ Group
                      { groupName = "Elea"
                      , place = "North Tyris"
                      , members =
                            [ Member
                                  { memberName = "Romias"
                                  , anotherName = "The messenger for Vindale"
                                  , age = Just 24
                                  , favoriteMoss = Nothing
                                  }
                            , Member
                                  { memberName = "Larnneire"
                                  , anotherName = "The listener of the wind"
                                  , age = Just 22
                                  , favoriteMoss = Nothing
                                  }
                            ]
                      }
                , Group
                      { groupName = "People in Vernis"
                      , place = "Vernis"
                      , members =
                            [ Member
                                  { memberName = "Vessel"
                                  , anotherName = "The white hawk"
                                  , age = Just 31
                                  , favoriteMoss = Nothing
                                  }
                            , Member
                                  { memberName = "Loyter"
                                  , anotherName = "The crimson of Zanan"
                                  , age = Just 32
                                  , favoriteMoss = Nothing
                                  }
                            ]
                      }
                ]
          }
    , World
          { worldName = "The world of Zakuzaku Actors"
          , groups =
                [ Group
                      { groupName = "Hagure Queendom"
                      , place = "Hagure Queendom"
                      , members =
                            [ Member
                                  { memberName = "Derich"
                                  , anotherName = "The queen of Hagure Queendom"
                                  , age = Nothing
                                  , favoriteMoss = Nothing
                                  }
                            , Member
                                  { memberName = "Rosemary"
                                  , anotherName = "Big moss"
                                  , age = Nothing
                                  , favoriteMoss = Just "Mossalcadia"
                                  }
                            ]
                      }
                ]
          }
    ]
```

<!--
## 下準備：`Data`型クラスの実装
-->

## Preparation: Implementing `Data` typeclass

<!--
`syb`を利用するためには，型が`Data`型クラスを実装している必要があります．`Data`型クラスの詳細についてはドキュメントを確認してください．
-->

A type must implement `Data` typeclass to use `syb`. See the documentation of the typeclass for the detail.

<!--
何はともあれまずは実装方法ですが，GHCの拡張機能である`DeriveDataTypeable`を有効にして，`deriving (Data)`で完了です．もちろん手動で実装することも可能ですが，deriveしたほうが楽です．
-->

A type can implement it just by enabling `DeriveDataTypeable` which is one of the GHC's language extensions and writing `deriving (Data)`. Of course, you can implement it by hands, but deriving is much easier.

<!--
以下の説明は，型に対し`Data`型クラスが適切に実装されていることを前提としています．
-->

The explanations below assume that types implement `Data` typeclass correctly.

<!--
## 使用例
-->

## Usage

<!--
### 特定の型の値だけを抽出する
-->

### Extract only values of a specific type

<!--
例えば`World`に含まれている`Member`をすべて抽出する関数を書きたいとしましょう．そのような関数を単純に書くと，以下の`membersFromWorld`関数のようになります．
-->

Suppose we want to write a function that extracts all `Member`s in a `World`. Such a function would look like the following `membersFromWorld` function.

<!--
```haskell
membersFromWorld :: World -> [Member]
membersFromWorld = concatMap members . groups
```
-->

```haskell
membersFromWorld :: World -> [Member]
membersFromWorld = concatMap members . groups
```

<!--
簡単ですね．以下のテストコードで動作を確かめることができます．
-->

Easy enough. You can verify the behavior with the following test code.

<!--
（本来テストコードは別の場所に書くべきですが，ここではGHCiなどの出力を載せる代わりにテストコードで実際の挙動を示しています．CIでテストコードを実行しているので，LTSなどのバージョンを上げた際，仮に将来動作が変更されたとしても，それに気付けるようにしています）
-->

(Normally, we should write test codes elsewhere, but I show functions' actual behaviors by them instead of, e.g., GHCi outputs. I run them in CI, which enables me to be aware of any future changes when I upgrade versions of LTS or something.)

<!--
```haskell
allMembersInWorld :: [Member]
allMembersInWorld =
    [ Member
          { memberName = "ロミアス"
          , anotherName = "異形の森の使者"
          , age = Just 24
          , favoriteMoss = Nothing
          }
    , Member
          { memberName = "ラーネイレ"
          , anotherName = "風を聴く者"
          , age = Just 22
          , favoriteMoss = Nothing
          }
    , Member
          { memberName = "ウェゼル"
          , anotherName = "ザナンの白き鷹"
          , age = Just 31
          , favoriteMoss = Nothing
          }
    , Member
          { memberName = "ロイター"
          , anotherName = "ザナンの紅の英雄"
          , age = Just 32
          , favoriteMoss = Nothing
          }
    , Member
          { memberName = "デーリッチ"
          , anotherName = "ハグレ王国国王"
          , age = Nothing
          , favoriteMoss = Nothing
          }
    , Member
          { memberName = "ローズマリー"
          , anotherName = "ビッグモス"
          , age = Nothing
          , favoriteMoss = Just "モスアルカディア"
          }
    ]

testMembersFromWorld :: Spec
testMembersFromWorld =
    describe "membersFromWorld" $
    it "`World`に含まれるすべての`Member`を返す．" $
    concatMap membersFromWorld worlds `shouldBe` allMembersInWorld
```
-->

```haskell
allMembersInWorld :: [Member]
allMembersInWorld =
    [ Member
          { memberName = "Romias"
          , anotherName = "The messenger for Vindale"
          , age = Just 24
          , favoriteMoss = Nothing
          }
    , Member
          { memberName = "Larnneire"
          , anotherName = "The listener of the wind"
          , age = Just 22
          , favoriteMoss = Nothing
          }
    , Member
          { memberName = "Vessel"
          , anotherName = "The crimson of Zanan"
          , age = Just 31
          , favoriteMoss = Nothing
          }
    , Member
          { memberName = "Loyter"
          , anotherName = "The crimson of Zanan"
          , age = Just 32
          , favoriteMoss = Nothing
          }
    , Member
          { memberName = "Derich"
          , anotherName = "The queend of Hagure Queendom"
          , age = Nothing
          , favoriteMoss = Nothing
          }
    , Member
          { memberName = "Rosemary"
          , anotherName = "Big moss"
          , age = Nothing
          , favoriteMoss = Just "Mossalcadia"
          }
    ]

testMembersFromWorld :: Spec
testMembersFromWorld =
    describe "membersFromWorld" $
    it "returns all `Member`s in a `World`" $
    concatMap membersFromWorld worlds `shouldBe` allMembersInWorld
```

<!--
今回の場合，`World`の構造があまり複雑ではないため，いくつかの関数を用いて簡単に抽出することが出来ました．しかし，例えば`Maybe`が使われていたり，構造がもっと大きく複雑だったり，型引数が使用されていたりすると，今回のようにセレクタ関数を組み合わせて抽出する方法は難しくなります．
-->

For this case, we could extract them easily by using a few functions because the structure of `World` was not so complex. However, it is difficult to do it with selector functions if, e.g., a data structure contains `Maybe`s, it has much bigger and more complex structure, or it has type variables.

<!--
そのような場合，sybの[`listify`](https://hackage.haskell.org/package/syb-0.7.2.2/docs/Data-Generics-Schemes.html#v:listify)関数を用いるとすんなり書けます．
-->

In such cases, we can write the function easily with the [`listify`](https://hackage.haskell.org/package/syb-0.7.2.2/docs/Data-Generics-Schemes.html#v:listify) function provided by syb.

<!--
```haskell
membersFromWorldWithListify :: World -> [Member]
membersFromWorldWithListify = listify onlyMember
  where
    onlyMember :: Member -> Bool
    onlyMember = const True

testMembersFromWorldWithListify :: Spec
testMembersFromWorldWithListify =
    describe "membersFromWorldWithListify" $
    it "`membersFromWorld`と同じ機能を持つ" $
    concatMap membersFromWorldWithListify worlds `shouldBe`
    concatMap membersFromWorld worlds
```
-->

```haskell
membersFromWorldWithListify :: World -> [Member]
membersFromWorldWithListify = listify onlyMember
  where
    onlyMember :: Member -> Bool
    onlyMember = const True

testMembersFromWorldWithListify :: Spec
testMembersFromWorldWithListify =
    describe "membersFromWorldWithListify" $
    it "has the same functionality with `testMembersFromWorld`" $
    concatMap membersFromWorldWithListify worlds `shouldBe`
    concatMap membersFromWorld worlds
```

<!--
`listify`関数は，抽出する値の条件を指定する関数を受け取り，「`Data`を実装する任意の型の値を受け取り，その値に含まれている値のうち，条件を満たす値をリストとして返す」関数を返します．
-->

The `listify` function receives a function that specifies the condition for values to be extracted and returns a function that takes values of any types implementing `Data` and returns a list of values that are included in the passed value and satisfy the condition.

<!--
`listify`関数のシグネチャは`Typeable r => (r -> Bool) -> GenericQ [r]`となっています．この`r`が，最終的なリストの要素の型となります．すなわちこの関数が返す関数は，受け取った値に含まれている型`r`の値に対し，それが条件を満たすかどうかを確認しています．上記の場合，`const True`で常に`True`を返すことで，型`r`の値を常に抽出するするようにします．
-->

The signature of the `listify` function is `Typeable r => (r -> Bool) -> GenericQ [r]`. The `r` is the type of the list which is finally returned. In other words, the function that `listify` returns checks if values of type `r` in the passed value satisfy the condition or not. In the above example, We specify the condition function with `const True` which always returns `True`, making the function extract all values of the type.

<!--
なお，`GenericQ`は`forall a. Data a => a -> r`のエイリアスです．また，[ドキュメントに記載されている](https://hackage.haskell.org/package/base-4.16.3.0/docs/Data-Typeable.html)ように，GHC7.10以降，全ての型は自動で`Typeable`をderiveしているため，型変数などを用いていなければ基本的に`listify`を任意の型に対して使用することができると考えて大丈夫です．以下に引用します．
-->

Note that `GenericQ` is an alias of `forall a. Data a => a -> r` and [as written in the document](https://hackage.haskell.org/package/base-4.16.3.0/docs/Data-Typeable.html), all types automatically derive `Typeable` since GHC 7.10, you can assume that you can use `listify` for any values of any types unless the type do not use any type variables. I'll quote the document as follows.

<!--
> Since GHC 7.10, all types automatically have Typeable instances derived. This is in contrast to previous releases where Typeable had to be explicitly derived using the DeriveDataTypeable language extension.
-->

> Since GHC 7.10, all types automatically have Typeable instances derived. This is in contrast to previous releases where Typeable had to be explicitly derived using the DeriveDataTypeable language extension.

<!--
引数で抽出する条件を指定するため，例えばモスアルカディアが好きな人物だけを抽出することも可能です．
-->

Since we specify the extraction condition by an argument, also we can extract characters who like Mossalcadia for example.

<!--
```haskell
listMossalcadiaMania :: World -> [Member]
listMossalcadiaMania = listify f
  where
    f :: Member -> Bool
    f = (== Just "モスアルカディア") . favoriteMoss

testListMossalcadiaMania :: Spec
testListMossalcadiaMania =
    describe "listMossalcadiaMania" $
    it "lists all `Member`s who love Mossalcadia" $
    concatMap listMossalcadiaMania worlds `shouldBe` expected
  where
    expected =
        [ Member
              { memberName = "ローズマリー"
              , anotherName = "ビッグモス"
              , age = Nothing
              , favoriteMoss = Just "モスアルカディア"
              }
        ]
```
-->

```haskell
listMossalcadiaMania :: World -> [Member]
listMossalcadiaMania = listify f
  where
    f :: Member -> Bool
    f = (== Just "Mossalcadia") . favoriteMoss

testListMossalcadiaMania :: Spec
testListMossalcadiaMania =
    describe "listMossalcadiaMania" $
    it "lists all `Member`s who love Mossalcadia" $
    concatMap listMossalcadiaMania worlds `shouldBe` expected
  where
    expected =
        [ Member
              { memberName = "Rosemary"
              , anotherName = "Big moss"
              , age = Nothing
              , favoriteMoss = Just "Mossalcadia"
              }
        ]
```

<!--
#### 特定の型の値を変更する
-->

#### Modify values of a specific type

<!--
妙な話ですが，例えば全ての集団が突然熊本城に召喚されたとしましょう．`Group`の`place`を全て"熊本城"に変更しなければなりません．やはりこれも小規模のデータ構造ならいくつの関数を定義すればどうにかなります．しかし大規模なものになると手に負えません．
-->

Strangely enough, but suppose all groups are suddenly summoned at Kumamoto Castle. We need to change the `place` values in all `Group`s to Kumamoto Castle. Again, we can achieve this by definiting a few functions for a small data structure, but it's too much work for a large one.

<!--
このような場合，`syb`で定義されている[`everywhere`](https://hackage.haskell.org/package/syb-0.7.2.2/docs/Data-Generics-Schemes.html#v:everywhere)を使うと楽に書けます．
-->

For this case, we can write it up easily with [`everywhere`](https://hackage.haskell.org/package/syb-0.7.2.2/docs/Data-Generics-Schemes.html#v:everywhere) defined in `syb`.

<!--
```haskell
summonAllGroupsInKumamotoCastle :: World -> World
summonAllGroupsInKumamotoCastle = everywhere (mkT f)
  where
    f :: Group -> Group
    f x = x {place = "熊本城"}

testSummonAllGroupsInKumamotoCastle :: Spec
testSummonAllGroupsInKumamotoCastle =
    describe "summonAllGroupsInKumamotoCastle" $
    it "`World`のすべての`Group`の`place`を\"熊本城\"に設定する" $
    nub (fmap place $ listify f $ fmap summonAllGroupsInKumamotoCastle worlds) `shouldBe`
    ["熊本城"]
  where
    f :: Group -> Bool
    f = const True
```
-->

```haskell
summonAllGroupsInKumamotoCastle :: World -> World
summonAllGroupsInKumamotoCastle = everywhere (mkT f)
  where
    f :: Group -> Group
    f x = x {place = "Kumamoto Castle"}

testSummonAllGroupsInKumamotoCastle :: Spec
testSummonAllGroupsInKumamotoCastle =
    describe "summonAllGroupsInKumamotoCastle" $
    it "sets \"Kumamoto Castle\" to the `place`s of all `Group`s in a `World`" $
    nub (fmap place $ listify f $ fmap summonAllGroupsInKumamotoCastle worlds) `shouldBe`
    ["Kumamoto Castle"]
  where
    f :: Group -> Bool
    f = const True
```

<!--
`everywhere`は値を変更するための関数を受け取り，「`Data`を実装している任意の型の値を受け取り，それに含まれている全ての値に対して，先に受け取った関数を適用する」関数を返します．`fmap`のようなものです．
-->

`everywhere` takes a function that modifies values and returns a function that takes values of any types implementing `Data` and applies the passed function to all of them. It's something like `fmap`.

<!--
`everywhere`のシグネチャは`(forall a. Data a => a -> a) -> forall a. Data a => a -> a`となっています．`listify`の場合，引数の型は`Typeable r => (r -> Bool)`でしたので，単純に`Member -> Bool`などと，適当な型の値を受け取って`Bool`値を返す関数を渡せばよいのですが，`everywhere`は`Data`を実装する任意の型を受け取って，同じ型の値を返す関数を定義しなければならず，ある特定の型の値に対する操作を行うのは不可能のように見えます．
-->

The signature of `everywhere` is `(forall a. Data a => a -> a) -> forall a. Data a => a -> a`. For `listify` we can just pass a function that receives a value of some type and returns a `Bool` value as the signature of its parameter is `Typeable r => (r -> Bool)`. However, `everywhere` requires us to define a function that receives a value of any type implementing `Data` and returns a value of the same type, which seems to make it impossible to operate on values of a specific type.

<!--
ここで利用するものが[`mkT`](https://hackage.haskell.org/package/syb-0.7.2.2/docs/Data-Generics-Aliases.html#v:mkT)です．`mkT`のシグネチャは`(Typeable a, Typeable b) => (b -> b) -> a -> a`ですが，この関数は，`b`型の値を受け取り，同じ型の値を返す関数を受け取り，それを`Typeable`な任意の型`a`の値を受け取り，同じ型の値を返す関数に拡張します．この際，受け取った値の型が実際には`b`である場合，受け取った関数を適用し，そうでなければ単純に受け取った値を返すようになります．以下に実行例を示します．
-->

This is where we use [`mkT`](https://hackage.haskell.org/package/syb-0.7.2.2/docs/Data-Generics-Aliases.html#v:mkT). Its signature is `(Typeable a, Typeable b) => (b -> b) -> a -> a`. It receives a function that takes a value of type `b` and returns a value of the same type, and extends it to a function that takes a value of any types implementing `Typeable` and returns a value of the same type. Here, it applies the passed function is the actual type of the given value is `b`, and returns the value as-is otherwise. The following code is an example.

<!--
```haskell
appendWorld :: String -> String
appendWorld = (++ " World")

appendWorldForData :: Data a => a -> a
appendWorldForData = mkT appendWorld

testAppendWorldForData :: Spec
testAppendWorldForData =
    describe "appendWorldForData" $ do
        it "受け取った値の型が`String`なら，\" World\"を付加する" $
            appendWorldForData "Hello" `shouldBe` "Hello World"
        it "受け取った値の型が`String`ではないなら，受け取った値をそのまま返す" $
            appendWorldForData (3 :: Int) `shouldBe` 3
```
-->

```haskell
appendWorld :: String -> String
appendWorld = (++ " World")

appendWorldForData :: Data a => a -> a
appendWorldForData = mkT appendWorld

testAppendWorldForData :: Spec
testAppendWorldForData =
    describe "appendWorldForData" $ do
        it "appends \"World\" if the type of the given value is `String`" $
            appendWorldForData "Hello" `shouldBe` "Hello World"
        it "returns the given value as-is if its type is not `String`" $
            appendWorldForData (3 :: Int) `shouldBe` 3
```

<!--
上記の熊本城の例では，関数`f :: Group -> Group`に`mkT`を適用したものを`everywhere`で使用しています．したがって，もし受け取った値の中に`Group`型の値が含まれているのならば，それの`place`を"熊本城"に変更します．別の型の値に対しては何も変更を加えません．
-->

In the above Kumamoto Castle example, we use `everywhere` with the function `f :: Group -> Group` applied with `mkT`. Therefore, it modifies the `place` to "Kumamoto Castle" if the passed value contains a value of `Group`. It does nothing for values of any other types.
