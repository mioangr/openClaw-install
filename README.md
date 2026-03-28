# openClaw-install
Infrastructure as code for a local AI agent environment.
Commands to install openClaw under linux. 

## Specifications

<pre>
Windows Host  
   └── VMware VM (Ubuntu Server)  
         ├── Docker  
         │     └── OpenClaw  
         ├── Limited filesystem  
         └── GitHub bot account (restricted)  
</pre>

Inside VM:
- keep repos:
  - ephemeral clones
- delete after tasks  
👉 minimizes persistence risk
