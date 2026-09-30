package com.bytebattle.coding.judge0;

import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestClient;
import org.springframework.http.client.JdkClientHttpRequestFactory;

import java.net.http.HttpClient;
import java.time.Duration;

@Configuration
@EnableConfigurationProperties(Judge0Properties.class)
public class Judge0Config {
    @Bean
    RestClient judge0RestClient(Judge0Properties properties) {
        HttpClient httpClient = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(3))
                .build();
        JdkClientHttpRequestFactory requestFactory = new JdkClientHttpRequestFactory(httpClient);
        requestFactory.setReadTimeout(Duration.ofSeconds(10));

        RestClient.Builder builder = RestClient.builder()
                .baseUrl(properties.getBaseUrl())
                .requestFactory(requestFactory);
        if (properties.getAuthToken() != null && !properties.getAuthToken().isBlank()) {
            builder.defaultHeader("X-Auth-Token", properties.getAuthToken());
        }
        return builder.build();
    }
}
