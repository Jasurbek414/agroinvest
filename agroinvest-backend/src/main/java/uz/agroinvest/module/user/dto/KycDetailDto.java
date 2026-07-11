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
    private String selfieUrl;
    private String passportPhotoUrl;
    private String currentAddress;
    private String registrationAddress;
    private String additionalPhone;
    private String fatherName;
    private String occupation;
    private String workExperience;
    private String education;
    private List<String> documentUrls;
}
