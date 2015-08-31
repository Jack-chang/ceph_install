iptables -A INPUT -p tcp --sport 6800 -j DROP
iptables -A INPUT -p tcp --sport 6801 -j DROP
iptables -A INPUT -p tcp --sport 6802 -j DROP
iptables -A INPUT -p tcp --sport 6803 -j DROP


iptables -A INPUT -p tcp --dport 6800 -j DROP
iptables -A INPUT -p tcp --dport 6801 -j DROP
iptables -A INPUT -p tcp --dport 6802 -j DROP
iptables -A INPUT -p tcp --dport 6803 -j DROP

iptables -L -n
