package com.thedevbranch.CodeDeployDemo;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/")
public class HomeController {

    @GetMapping("/health")
    public String health(){
        return "I am healthy.";
    }
    
    @GetMapping("/hi")
    public String hello(){
        return "Hello my friend.";
    }
}
