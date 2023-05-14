# Voyager
Enter the world of SQLillo Royale, where agents fight to the death. Using efficient & novel approaches for obstacle evasion, target acquirement and action choices, we achieve top performance metrics.

[Github](https://github.com/lucashc/Voyager) [Devpost]()

## Inspiration
Gaudi's architecture taught us to learn from nature, and it is in this light that we have developed our natural and elegant approach to multiplayer games. We have strived to incorporate natural elements in our work, namely those of hyperboloid surfaces and exponential functions. To this end, we have used these extensively in our agent's decision-making.
## What it does
Voyager is an agent, optimised for playing SQLillo Royale. We are able to achieve top level performance using revolutionary efficient new algorithmic process for mechanical dodging, target analysis and environmental awareness.
## How we built it
Using Lua (and sort of C) and also Python, as well as extensive Github actions. 
## Challenges we ran into
Having to fix bugs in a game that we are supposed to optimise playing is an interesting experience. It was a big challenge to develop a suitable algorithm to play the game, since this required knowing the mechanics and gameplay inside out, and being able to formulate an optimisation problem to transfer to code.
## Accomplishments that we're proud of
None of us had any experience coding in Lua, so developing a highly performant algorithm for this game was a great accomplishment. We are also very proud of our github actions pipeline we created, which streamlined the process of uploading our agents to the server, as well as calculating analytics and feedback on the agent's performance directly.
## The Algorithm
Our algorithm consists of three main steps:
- [x] Enemy avoidance (bullets & players)
- [x] Staying in the safe zone
- [x] Action choice & targetting
Each of these are subject to various complications. For example, the type of play later in the game may be substantially different to earlier in the game.
## Github Actions Pipeline
We were able to make our life much easier by setting up a sophisticated github workflow. Our project required uploading code onto a server in order to determine the performance of our agent. This would be a very manual process, but we were able to have it automatically occur whenever code was pushed onto github. Furthermore, we were also able to automatically generate a summary of our new agent's performance as well.
## What we learned
Lua, Github actions, game mechanics
## What's next for Voyager
Space: The Final Frontier