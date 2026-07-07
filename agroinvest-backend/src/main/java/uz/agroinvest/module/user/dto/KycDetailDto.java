package uz.agroinvest.module.user.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.util.List;

@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class KycDetailDto {
    private String passportNumber;
    private String pinfl;
    private String birthDate;
    private List<String> documentUrls;
}
