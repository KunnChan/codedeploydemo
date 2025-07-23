package com.thedevbranch.CodeDeployDemo;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/hi")
public class HomeController {

    @GetMapping
    public String hello(){
        return "Hello";
    }
}
