---
title: AI改变了我查单词的方式
date: 2025-08-20
updated: 2025-08-21
draft: false
taxonomies:
  categories:
    - AI
  tags:
    - AI
    - 学习方法
    - 工具推荐
---

<script type="module">
  import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs';
</script>

<style>
.mermaid-container {
  position: relative;
  cursor: pointer;
  border: 1px solid #e1e5e9;
  border-radius: 6px;
  padding: 16px;
  margin: 16px 0;
  transition: all 0.2s ease;
}

.mermaid-container:hover {
  border-color: #1976d2;
  box-shadow: 0 2px 8px rgba(25, 118, 210, 0.1);
}

.mermaid-hint {
  text-align: center;
  font-size: 12px;
  color: #666;
  margin-top: 8px;
  opacity: 0.8;
}

.diagram-modal {
  display: none;
  position: fixed;
  z-index: 1000;
  left: 0;
  top: 0;
  width: 100%;
  height: 100%;
  background-color: rgba(0,0,0,0.8);
  animation: fadeIn 0.3s ease;
}

.diagram-modal-content {
  position: relative;
  background-color: white;
  margin: 2% auto;
  padding: 20px;
  width: 95%;
  max-width: 1400px;
  max-height: 90%;
  overflow: auto;
  border-radius: 8px;
  animation: slideIn 0.3s ease;
}

.diagram-close {
  position: absolute;
  top: 15px;
  right: 25px;
  font-size: 32px;
  font-weight: bold;
  cursor: pointer;
  color: #666;
  z-index: 1001;
}

.diagram-close:hover {
  color: #000;
}

.diagram-modal .mermaid {
  transform: scale(1.5);
  transform-origin: top left;
  margin: 20px;
  max-width: none;
  width: auto;
  min-width: 200%;
  min-height: 250%;
  overflow: visible;
}

.diagram-modal-content {
  overflow-x: auto;
  overflow-y: auto;
  padding: 20px;
  max-height: 90vh;
}

@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}

@keyframes slideIn {
  from { transform: translateY(-50px); opacity: 0; }
  to { transform: translateY(0); opacity: 1; }
}

@media (max-width: 768px) {
  .diagram-modal .mermaid {
    transform: scale(2);
    transform-origin: top left;
    margin: 15px;
    min-width: 180%;
    min-height: 200%;
  }

  .diagram-modal-content {
    width: 98%;
    margin: 1% auto;
    padding: 15px;
    max-height: 85vh;
  }
}
</style>

<script>
document.addEventListener('DOMContentLoaded', function() {
  // 为所有mermaid图表添加点击事件
  document.querySelectorAll('.mermaid-container').forEach(function(container) {
    container.addEventListener('click', function() {
      openDiagramModal(this);
    });
  });
});

function openDiagramModal(container) {
  const mermaidElement = container.querySelector('.mermaid');
  if (!mermaidElement) return;

  // 克隆mermaid元素并重新渲染以获得更大的版本
  const clonedMermaid = mermaidElement.cloneNode(true);

  // 创建模态框
  const modal = document.createElement('div');
  modal.className = 'diagram-modal';
  modal.innerHTML = `
    <div class="diagram-modal-content">
      <span class="diagram-close">&times;</span>
      <div style="text-align: center; margin-bottom: 20px;">
        <h3 style="margin: 0; color: #333;">流程图详细视图</h3>
      </div>
      <div style="overflow-x: auto; overflow-y: auto; max-height: 80vh; min-height: 500px;">
        <div id="enlarged-mermaid"></div>
      </div>
    </div>
  `;

  document.body.appendChild(modal);
  modal.style.display = 'block';

  // 将克隆的mermaid元素添加到放大容器中
  const enlargedContainer = modal.querySelector('#enlarged-mermaid');
  enlargedContainer.appendChild(clonedMermaid);

  // 关闭功能
  const closeBtn = modal.querySelector('.diagram-close');
  closeBtn.onclick = function() {
    closeDiagramModal(modal);
  };

  // 点击背景关闭
  modal.onclick = function(event) {
    if (event.target === modal) {
      closeDiagramModal(modal);
    }
  };

  // ESC键关闭
  const escHandler = function(event) {
    if (event.key === 'Escape') {
      closeDiagramModal(modal);
      document.removeEventListener('keydown', escHandler);
    }
  };
  document.addEventListener('keydown', escHandler);
}

function closeDiagramModal(modal) {
  modal.style.animation = 'fadeOut 0.3s ease';
  setTimeout(function() {
    if (document.body.contains(modal)) {
      document.body.removeChild(modal);
    }
  }, 300);
}
</script>

## 前言

*在ChatGPT出现之后，我发现传统词典作为查词工具存在许多不足；它不仅在效率上非常低，而且在设计上也存在根本的不足。*

*而因为这些缺陷和不足，导致我们浪费了大量的时间和心力在不必要的操作上，非常影响我们的外语学习和阅读体验。*

*在下文中我将对比传统词典和ChatGPT，解释为什么更建议你使用AI来代替传统的词典，并且推荐一个优秀的工具来更好地利用AI帮助你阅读和学习外语。*

## Part1 传统查词 vs AI查词

假设现在存在这样一个句子，我不理解这里bank的含义：

> I need to go to the **bank** to deposit my paycheck.


在过去我通常会使用电子词典来查询，基本上流程如下：

<div class="mermaid-container">
<pre class="mermaid">
graph TD
    A[遇到不认识的单词: bank] --> B[打开电子词典]
    B --> C[输入单词]
    C --> D[获取所有含义<br/>银行、河岸、堤坝、倾斜...]
    D --> E[逐一阅读理解]
    E --> F[返回原句子<br/>I need to go to the bank to deposit my paycheck]
    F --> G[根据上下文判断<br/>deposit paycheck = 存工资]
    G --> H[单词在句子中的准确含义: 银行]
</pre>
<div class="mermaid-hint">💡 电子词典查词需要8个步骤</div>
</div>


我需要先输入单词，获取到bank的所有含义后（大概十几，二十多种），然后逐一进行查阅，然后带着以上含义回到句子，因为有deposit my paycheck（将我的工资存入），最后确定这里应该是银行的意思。

而在ChatGPT出现后，步骤会简单和直观得多，通常就只是两步：

<div class="mermaid-container">
<pre class="mermaid">
graph TD
    A[遇到不认识的单词: bank] --> B[选取单词和句子<br/>I need to go to the bank to deposit my paycheck]
    B --> C[复制粘贴到ChatGPT<br/>问：这个句子中bank的含义？]
    C --> D[单词在句子中的准确含义: 银行<br/>金融机构，人们存钱、取钱的地方]
</pre>
<div class="mermaid-hint">💡 ChatGPT查词只需2个步骤</div>
</div>


### 对比

<div class="mermaid-container">
<pre class="mermaid">
graph TD
    A[遇到不认识的单词] --> B[传统词典查词]
    A --> C[AI查词]
    B --> D[输入单词]
    D --> E[获取所有含义]
    E --> F[逐一阅读理解]
    F --> G[返回原句子]
    G --> H[根据上下文判断]
    H --> I[单词在句子中的准确含义]
    C --> J[选取单词+句子]
    J --> K[输入到ChatGPT]
    K --> L[单词在句子中的准确含义]
</pre>
<div class="mermaid-hint">💡 把两个流程图放一起能够更加清晰地展示了两种查词方式的差异。</div>
</div>

相比传统查词，AI帮助我们跳过了中间阅读所有含义和确定准确含义的步骤，直接获得我们想要的结果，不用多说也知道哪一种方式更加省心省力。

## Part2 为什么建议使用AI来代替你的传统查词方式

在ChatGPT出现之后，我才意识到这个问题：

**当我们查单词时，我们需要的不是单词的所有含义，而是单词在句子中的含义**。

在传统词典中，我们只能输入单词，然后输出单词的所有含义，但这并不是我们想要的最终结果，我们还需要对词典给出的结果再额外进行处理，也就是代入进句子看哪一个含义才是最合适的。

如果每个单词只有两三种含义，那么也许也并不算一个问题，但问题是许多常见单词都存在有几十种含义，比如make，在《陆谷孙英汉大词》里用了近十页A4纸大小来解释它在不同上下文中的具体含义。

对于非母语者来说，往往需要消耗大量时间和心力来阅读这些含义，并且还要根据当前的上下文来确定最后的准确含义，这非常影响我们的阅读体验。

<div class="mermaid-container">
<pre class="mermaid">
graph TD
    A[单词: make] --> B[传统词典]
    A --> C[AI查词]
    B --> D[制作]
    B --> E[使得]
    B --> F[赚取]
    B --> G[到达]
    B --> H[品牌]
    B --> I[还有20+种含义...]
    I --> J[用户需要判断上下文]
    J --> K1[制造相关上下文 → 制作]
    J --> K2[因果相关上下文 → 使得]
    J --> K3[金钱相关上下文 → 赚取]
    J --> K4[目标相关上下文 → 到达]
    C --> L[直接理解上下文]
    L --> M[单词在句子中的准确含义]
</pre>
<div class="mermaid-hint">💡 传统词典：需要人工判断上下文 vs AI：自动理解上下文</div>
</div>

而且如果你有做过翻译这门工作，你可能会发现这种情况：当你打开词典想要为某个词汇在句子中找到合适的翻译时，反复查找，确认，但词典中的哪一个含义看上去好像都不对！

但这不是词典出错了，而是因为单词在实际生活中的含义比词典中的还要多得多。

**一个单词在不同的上下文语境中的含义非常非常多样，多到以词典的篇幅根本无法完全收录，往往收录的只是最常见的含义**。

但即使只是收录常见含义，也已经足够巨大，《陆谷孙英汉大词典》大概得有七八块砖头叠起来那么大，但即使如此，我在翻译时也经常无法找到合适的释义，往往只能去寻求母语使用者的帮助。

另外还有一种情况，那就是**许多词汇只有在具体的上下文语境才能真正得到准确的含义**，而词典只能输入词汇，无法输入上下文，从根本上词典就无法解决这个问题。

在过去没有选择和对比时，传统词典似乎是唯一可行且有效的选择，但在ChatGPT出现后，传统词典就像一台早已性能落后的电脑，追不上更新迭代，已经远远带不动如今查询单词所需要的功能和性能了.

对比ChatGPT，词典这种工具似乎从设计上就存在不足，它注定只是一种搜集工具，而不能是一种符合我们真正需要的查词工具。


### 我们能够信任AI给出的查词结果吗？

自从ChatGPT出来以后就一直存在的争议：我们能够信任AI给出的结果吗？

我的答案是，我更建议你先尝试自己使用看看，复制一段句子，然后问AI能否解释清楚单词在句子中的含义。

AI的回答是否正确实际上取决于许多因素；像如果是对于史料，你最好不要相信任何AI给出的结果，这不是它的功能，它不是搜索引擎；但如果是解释单词词汇的含义，用来学习语言，它可以是当今世界上最好用的工具。

从理论上来说，我们应该保持质疑，ChatGPT也始终强调它给出的含义可能是错误的；但从我这近一年多的使用体验上来看，如果输出单词的同时输入单词所在的句子，那输出的正确率达到非常惊人的百分之百，ChatGPT完全正确解释了所有我在外语阅读中的英语词汇，没错，是所有。

但即使如此，我们仍然需要保持质疑，有必要时进行检查——实际上即使是对于权威词典，我们也应该保持这样的态度，因为权威词典也可能会出错。



## 解决ChatGPT作为查词工具的不足

在学会使用ChatGPT查询单词后，我几乎就再也没用过传统词典来查字典了，但ChatGPT的使用仍然不够方便。

相比传统词典，使用ChatGPT确实又直观又准确，但是这整个流程还是太麻烦，因为每次都需要将单词和句子复制，粘粘到ChatGPT。

如果只是一两次还好，但一篇文章中通常会有很多个需要查询的单词和句子，如果每次都这样复制粘贴，在ChatGPT和阅读界面之间切换，浪费时间不说，也非常影响阅读体验。于是我就想着能不能把整个流程缩短为最为简单的步骤：

1. 鼠标选取单词，同时获取到单词所在的上下文句子

2. 使用ai获取单词在句子中的含义

3. （如果有需要）一键添加到[Anki](https://apps.ankiweb.net/)中复习

作为一个独立开发者，说做就做，于是在半年后有了Elick这个工具，它完美解决了ChatGPT的不足：不需要复制粘贴，也不需要切换界面，整个流程只需要点击几下鼠标，就能一键从一个陌生的单词直达它在句子中的准确的含义。

[点击查看Elick的查词示例](https://assets.elick.it.com/cdn/gifs/elick-demo-zh.gif)

而且Elick还支持查询单词在YouTube中的真人发音，并且将查询的单词添加到anki，在手机和电脑上同步复习。

通过Elick，你可以抛弃枯燥且低效的死记单词方式，直接通过阅读的方式来学习单词。

现在Elick已经上线，你可以在官网下载并且免费试用。

也许听上去像是王婆卖瓜，自卖自夸，但我是真觉得，Elick给我带来了一种非常顺滑和自然的查单词体验，很难用言语形容，就有种仿佛查单词本来就应该是这样的奇妙体验；而因为查词如此方便后，我的阅读也轻松了很多。

## 不仅仅是查单词

Elick不只是一个查词工具，当你熟练掌握它的使用后，它可以是一个将所有AI能够实现的简单操作都变得更方便的快捷工具。

比如Elick能够在鼠标划取单词时获取到对应的句子，那么也能够划取一个句子，解释句子在整个上下文的含义，或者分析结构。

又或者优化自己的外语表达，划取自己的外语表达，然后一键进行优化。

---

## 🎯 立即体验

如果你对这个工具感兴趣，欢迎访问 **[Elick官网](https://elick.it.com/)** 免费下载试用！

🔗 **相关链接：**
- [Elick官网](https://elick.it.com/) - 下载和试用
- [ChatGPT](https://chat.openai.com/) - AI对话工具
- [Anki](https://apps.ankiweb.net/) - 间隔重复学习工具
