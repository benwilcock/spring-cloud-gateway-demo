package com.scg.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@SpringBootApplication
public class SecuredServiceApplication {

  public static void main(String[] args) {
    SpringApplication.run(SecuredServiceApplication.class, args);
  }

  private static final Logger LOG = LoggerFactory.getLogger(SecuredServiceApplication.class);

  @GetMapping("/resource")
  public String resource(@AuthenticationPrincipal Jwt jwt) {
    LOG.trace("***** JWT Headers: {}", jwt.getHeaders());
    LOG.trace("***** JWT Claims: {}", jwt.getClaims().toString());
    LOG.trace("***** JWT Token: {}", jwt.getTokenValue());
    return String.format("Resource accessed by: %s (with subjectId: %s)" ,
            jwt.getClaims().get("user_name"),
            jwt.getSubject());
  }
}
