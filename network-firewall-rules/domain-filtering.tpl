%{ for idx, domain in domains ~}
pass tls any any -> any any (msg:"Allow ${domain}"; tls.sni; content:"${domain}"; endswith; sid:${idx}; rev:1;)
%{ endfor ~}
drop tls any any -> any any (msg:"Drop other TLS"; sid:${length(domains)}; rev:1;)
%{ for idx, domain in domains ~}
pass http any any -> any any (msg:"Allow ${domain} HTTP"; http.host; content:"${domain}"; endswith; sid:${length(domains) + idx}; rev:1;)
%{ endfor ~}
drop http any any -> any any (msg:"Drop other HTTP"; sid:${length(domains) + length(domains)}; rev:1;)
