package uz.agroinvest.module.dispute.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import uz.agroinvest.common.enums.DisputeStatus;

import java.time.LocalDateTime;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class DisputeDto {
    private UUID id;
    private UUID projectId;
    private String projectTitle;
    private UUID filedById;
    private String filedByName;
    private UUID againstUserId;
    private String againstUserName;
    private String disputeType;
    private String description;
    private DisputeStatus status;
    private String resolution;
    private LocalDateTime createdAt;
}
